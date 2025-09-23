class MoveCommentsSearchController < ApplicationController
  before_action :require_login

  def issues
    term = params[:term].to_s.strip
    return render json: [] if term.blank?

    # Simple subject search (case-insensitive)
    issues = Issue.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{term}%")
                  .order(:id)
                  .limit(15)
                  .pluck(:id, :subject)

    render json: issues.map { |id, subject| { id: id, subject: subject } }
  end
end

