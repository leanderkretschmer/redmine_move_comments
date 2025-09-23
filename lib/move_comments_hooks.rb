# frozen_string_literal: true

# Hook class for Redmine Move Comments Plugin
# Provides functionality to move comments between issues
class MoveCommentsHooks < Redmine::Hook::Listener
  
  # Renders the 'Move comment to another issue' form field
  # This hook is called after the notes form in the journal edit view
  # 
  # @param context [Hash] The context hash containing controller and other data
  # @return [String] Rendered HTML for the move comment form field
  def view_journals_notes_form_after_notes(context = {})
    return '' unless context[:controller]
    
    # Get user tickets if setting is enabled
    user_tickets = []
    if show_user_tickets_enabled?
      user_tickets = get_user_tickets(User.current)
    end
    
    context[:controller].render_to_string(
      partial: 'notes_edit',
      locals: {
        user_tickets: user_tickets,
        show_user_tickets: show_user_tickets_enabled?,
        enable_ticket_search: ticket_search_enabled?,
        show_project_info: project_info_enabled?
      }
    )
  end
 
  # Processes the journal edit form submission and moves the comment if requested
  # This hook is called after a journal edit POST request
  # 
  # @param context [Hash] The context hash containing params, journal, and other data
  # @return [void]
  def controller_journals_edit_post(context = {})
    return unless context[:journal] && context[:params]
    
    new_issue_id = context[:params]['new_issue_id']
    
    # Add accessor for error tracking
    context[:journal].class.module_eval { attr_accessor :wrong_new_issue_id }
    context[:journal].wrong_new_issue_id = nil
    
    return unless new_issue_id.present?
    
    current_journal = context[:journal]
    target_issue = find_target_issue(new_issue_id)
    
    if target_issue.nil?
      # Store the invalid ID for error display
      context[:journal].wrong_new_issue_id = new_issue_id
      return
    end
    
    move_journal_to_issue(current_journal, target_issue)
  end
  
  private
  
  # Checks if the show user tickets setting is enabled
  # 
  # @return [Boolean] True if setting is enabled, false otherwise
  def show_user_tickets_enabled?
    Setting.plugin_redmine_move_comments['show_user_tickets'] == '1'
  end
  
  # Checks if ticket search is enabled
  # 
  # @return [Boolean] True if setting is enabled, false otherwise
  def ticket_search_enabled?
    Setting.plugin_redmine_move_comments['enable_ticket_search'] == '1'
  end
  
  # Checks if project info display is enabled
  # 
  # @return [Boolean] True if setting is enabled, false otherwise
  def project_info_enabled?
    Setting.plugin_redmine_move_comments['show_project_info'] == '1'
  end
  
  # Checks if owned tickets should be shown
  # 
  # @return [Boolean] True if setting is enabled, false otherwise
  def show_owned_tickets_enabled?
    Setting.plugin_redmine_move_comments['show_owned_tickets'] == '1'
  end
  
  # Checks if commented tickets should be shown
  # 
  # @return [Boolean] True if setting is enabled, false otherwise
  def show_commented_tickets_enabled?
    Setting.plugin_redmine_move_comments['show_commented_tickets'] == '1'
  end
  
  # Gets tickets where the user has commented or owns
  # 
  # @param user [User] The user to search tickets for
  # @param search_term [String] Optional search term to filter by subject
  # @return [Array<Hash>] Array of hashes with ticket details
  def get_user_tickets(user, search_term = nil)
    return [] unless user
    
    issue_ids = []
    
    # Add commented tickets if enabled
    if show_commented_tickets_enabled?
      commented_ids = Journal.joins(:issue)
                            .where(user_id: user.id, journalized_type: 'Issue')
                            .where.not(notes: [nil, ''])
                            .distinct
                            .pluck(:journalized_id)
      issue_ids.concat(commented_ids)
    end
    
    # Add owned tickets if enabled
    if show_owned_tickets_enabled?
      owned_ids = Issue.where(assigned_to_id: user.id).pluck(:id)
      issue_ids.concat(owned_ids)
    end
    
    return [] if issue_ids.empty?
    
    # Build query for issues
    query = Issue.joins(:project)
                 .where(id: issue_ids.uniq)
    
    # Add search filter if provided
    if search_term.present?
      query = query.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{search_term}%")
    end
    
    # Get issue details with project info
    if project_info_enabled?
      query.limit(15)
           .order(:id)
           .pluck(:id, :subject, 'projects.name')
           .map { |id, subject, project| { id: id, subject: subject, project: project } }
    else
      query.limit(15)
           .order(:id)
           .pluck(:id, :subject)
           .map { |id, subject| { id: id, subject: subject } }
    end
  end
  
  # Finds the target issue by ID with error handling
  # 
  # @param issue_id [String, Integer] The ID of the target issue
  # @return [Issue, nil] The found issue or nil if not found/invalid
  def find_target_issue(issue_id)
    Issue.find(issue_id)
  rescue ActiveRecord::RecordNotFound, ArgumentError
    nil
  end
  
  # Moves a journal (comment) from one issue to another
  # 
  # @param source_journal [Journal] The journal to move
  # @param target_issue [Issue] The target issue to move the journal to
  # @return [void]
  def move_journal_to_issue(source_journal, target_issue)
    # Create new journal for target issue
    new_journal = Journal.new(
      journalized_id: target_issue.id,
      journalized_type: source_journal.journalized_type,
      user_id: source_journal.user_id,
      notes: source_journal.notes,
      private_notes: source_journal.private_notes,
      created_on: source_journal.created_on
    )
    
    return unless new_journal.save
    
    # Move attachments referenced by the source journal to the target issue
    # and recreate their journal details on the new journal
    attachment_details = source_journal.details.select { |d| d.property == 'attachment' }
    attachment_details.each do |detail|
      attachment_id = detail.prop_key.to_i
      attachment = Attachment.find_by(id: attachment_id)
      next unless attachment

      # Reassign attachment to the target issue
      attachment.container = target_issue
      # If Redmine version has journal_id tracking on Attachment, update it as well
      attachment.journal_id = new_journal.id if attachment.respond_to?(:journal_id=)
      attachment.save!

      # Recreate the journal detail on the new journal so history remains accurate
      JournalDetail.create!(
        journal: new_journal,
        property: detail.property,
        prop_key: detail.prop_key,
        value: detail.value
      )

      # Remove the attachment detail from the source journal
      detail.destroy
    end

    # Reload to reflect removed details
    source_journal.reload

    # Clean up source journal
    if source_journal.details.empty?
      source_journal.destroy
    else
      source_journal.update(notes: nil)
    end
  end
  
  public
  
  # Renders error message if journal move failed
  # This hook is called at the bottom of journal update JavaScript responses
  # 
  # @param context [Hash] The context hash containing journal and controller
  # @return [String, nil] Rendered error JavaScript or nil if no error
  def view_journals_update_js_bottom(context = {})
    return unless context[:journal] && context[:controller]
    
    wrong_new_issue_id = context[:journal].wrong_new_issue_id
    return if wrong_new_issue_id.nil?
    
    context[:controller].render_to_string(
      partial: 'notes_error',
      locals: {
        wrong_new_issue_id: wrong_new_issue_id
      }
    )
  end
 
end
