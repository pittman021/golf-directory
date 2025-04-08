# app/controllers/admin/imports_controller.rb
class Admin::ImportsController < Admin::BaseController
    def new
    end
  
    def create
      if params[:file].present?
        results = CourseImportService.import(params[:file])
        
        if results[:failed] > 0
          flash[:alert] = "Import completed with errors. Created: #{results[:created]}, Updated: #{results[:updated]}, Failed: #{results[:failed]}"
          session[:import_errors] = results[:errors]
        else
          flash[:notice] = "Import successful! Created: #{results[:created]}, Updated: #{results[:updated]}"
        end
      else
        flash[:alert] = "Please select a file to import"
      end
      
      redirect_to new_admin_import_path
    end
  end