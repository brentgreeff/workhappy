class HomeController < ApplicationController
  def index
    @earliest, @latest = Current.company.assessments.pick(Arel.sql("MIN(created_at)"), Arel.sql("MAX(created_at)"))
  end
end
