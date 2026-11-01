class AssessmentsController < ApplicationController
  PER_PAGE = 50

  def index
    @filter = AssessmentFilter.new(filter_params)
    @page = [params[:page].to_i, 1].max
    @earliest, @latest = Current.company.assessments.pick(Arel.sql("MIN(created_at)"), Arel.sql("MAX(created_at)"))

    if @filter.valid?
      list_page
    else
      flash.now[:alert] = @filter.errors.full_messages.to_sentence
      @assessments = []
    end
  end

  private

  def filter_params
    params.fetch(:filter, {}).permit(:from_date, :to_date, :status)
  end

  def list_page
    scope = @filter.apply(Current.company.assessments)
    @pages = [(scope.count / PER_PAGE.to_f).ceil, 1].max
    @page = @page.clamp(1, @pages)
    @assessments = scope.preload(:employee)
      .order(created_at: :desc, id: :desc)
      .offset((@page - 1) * PER_PAGE)
      .limit(PER_PAGE)
      .to_a
  end
end
