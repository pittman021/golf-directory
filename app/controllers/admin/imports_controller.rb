# app/controllers/admin/imports_controller.rb
module Admin
    class ImportsController < ApplicationController
      before_action :authenticate_user!
      before_action :verify_admin
  
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
  
      private
  
      def verify_admin
        unless current_user&.admin?
          redirect_to root_path, alert: 'You are not authorized to access this area.'
        end
      end
    end
  end