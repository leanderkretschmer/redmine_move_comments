class MoveCommentsSearchController < ApplicationController
  before_action :require_login

  def issues
    term = params[:term].to_s.strip
    return render json: [] if term.blank?

    query = Issue.visible(User.current)

    # Support Suche nach ID ("499" oder "#499") und nach Titel
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
end

