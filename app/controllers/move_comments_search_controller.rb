class MoveCommentsSearchController < ApplicationController
  before_action :require_login

  def issues
    term = params[:term].to_s.strip
    project_id = params[:project_id]
    return render json: [] if term.blank?

    query = Issue.visible(User.current)
    query = query.where(project_id: project_id) if project_id.present?

    if term.start_with?('#') && term[1..-1].to_s =~ /^\d+$/
      id_num = term[1..-1].to_i
      query = query.where(id: id_num)
    elsif term =~ /^\d+$/
      query = query.where(id: term.to_i)
    else
      query = query.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{term}%")
    end

    issues = query.joins(:project)
                  .order(:id)
                  .limit(15)
                  .pluck(:id, :subject, 'projects.name')

    render json: issues.map { |id, subject, project| { id: id, subject: subject, project: project } }
  end

  def check_issue_project
    issue_id = params[:issue_id].to_s.strip
    return render json: { error: 'not_found' }, status: :not_found if issue_id.blank?

    issue = Issue.visible(User.current).find_by(id: issue_id.to_i)
    return render json: { error: 'not_found' }, status: :not_found unless issue

    render json: {
      project_id: issue.project_id,
      project_name: issue.project.name,
      issue_id: issue.id,
      subject: issue.subject
    }
  end
end

