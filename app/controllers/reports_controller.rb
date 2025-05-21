class ReportsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:public_class_report]

  def public_class_report
    @class_standard = ClassStandard.find_by!(code: params[:class_standard])
    @report = @class_standard.attendance_report
    @total_classes = @report.first&.dig(:total_classes) || 0
    @short_attendance_threshold = 75

    respond_to do |format|
      format.html
      format.json { render json: @report }
      format.pdf do
        render pdf: "attendance_report_#{@class_standard.code}",
               template: "reports/public_class_report",
               layout: 'pdf',
               disposition: 'inline'
      end
    end
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Class not found"
    redirect_to root_path
  end

  def download
    @class_standard = ClassStandard.find_by!(code: params[:class_standard])
    @report = @class_standard.attendance_report

    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=attendance_report_#{@class_standard.code}.xlsx"
      end
    end
  end
end 