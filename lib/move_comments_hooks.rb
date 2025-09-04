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
        show_user_tickets: show_user_tickets_enabled?
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
  
  # Gets tickets where the user has commented
  # 
  # @param user [User] The user to search tickets for
  # @return [Array<Hash>] Array of hashes with :id and :subject
  def get_user_tickets(user)
    return [] unless user
    
    # Find issues where user has journals (comments)
    issue_ids = Journal.joins(:issue)
                      .where(user_id: user.id, journalized_type: 'Issue')
                      .where.not(notes: [nil, ''])
                      .distinct
                      .pluck(:journalized_id)
    
    # Get issue details
    Issue.where(id: issue_ids)
         .limit(10) # Limit to avoid performance issues
         .order(:id)
         .pluck(:id, :subject)
         .map { |id, subject| { id: id, subject: subject } }
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
