# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # Data Analytics Dashboard
    div class: "dashboard_section" do
      h2 "🏌️ Golf Directory Analytics Dashboard"
      
      # Overall Statistics
      columns do
        column do
          panel "📊 Database Overview" do
            total_courses = Course.count
            total_locations = Location.count
            total_states = State.count
            
            ul do
              li "Total Courses: #{number_with_delimiter(total_courses)}"
              li "Total Locations: #{total_locations}"
              li "Total States: #{total_states}"
              li "Avg Courses/State: #{(total_courses.to_f / total_states).round(1)}"
            end
          end
        end
        
        column do
          panel "🎯 Data Quality Score" do
            total_courses = Course.count
            
            # Calculate scores
            descriptions = Course.where("description IS NOT NULL AND LENGTH(description) > 50").count
            images = Course.where("image_url IS NOT NULL AND image_url != ''").count
            websites = Course.where("website_url IS NOT NULL AND website_url != '' AND website_url NOT LIKE '%Pending%'").count
            amenities = Course.where.not("amenities IS NULL OR ARRAY_LENGTH(amenities, 1) IS NULL").count
            google_data = Course.where("google_place_id IS NOT NULL").count
            
            # Calculate weighted score
            description_score = (descriptions.to_f / total_courses) * 15
            image_score = (images.to_f / total_courses) * 15
            website_score = (websites.to_f / total_courses) * 20
            amenities_score = (amenities.to_f / total_courses) * 15
            google_score = (google_data.to_f / total_courses) * 20
            contact_score = 15 # Simplified for display
            
            total_score = description_score + image_score + website_score + amenities_score + google_score + contact_score
            
            div style: "font-size: 24px; font-weight: bold; color: #{total_score > 50 ? '#28a745' : total_score > 30 ? '#ffc107' : '#dc3545'};" do
              "#{total_score.round(1)}/100"
            end
            
            ul do
              li "Descriptions: #{((descriptions.to_f / total_courses) * 100).round(1)}%"
              li "Images: #{((images.to_f / total_courses) * 100).round(1)}%"
              li "Websites: #{((websites.to_f / total_courses) * 100).round(1)}%"
              li "Amenities: #{((amenities.to_f / total_courses) * 100).round(1)}%"
              li "Google Data: #{((google_data.to_f / total_courses) * 100).round(1)}%"
            end
          end
        end
      end
      
      # Recent Activity
      columns do
        column do
          panel "📅 Recent Activity (30 days)" do
            recent_courses = Course.where("created_at > ?", 30.days.ago).count
            recent_updates = Course.where("updated_at > ? AND updated_at != created_at", 30.days.ago).count
            
            ul do
              li "New Courses: #{recent_courses}"
              li "Updated Courses: #{recent_updates}"
            end
            
            # Show recent additions by state
            recent_by_state = Course.joins(:state)
                                   .where("courses.created_at > ?", 30.days.ago)
                                   .group('states.name')
                                   .count
                                   .sort_by { |_, count| -count }
                                   .first(5)
            
            if recent_by_state.any?
              h4 "Top States for New Courses:"
              ul do
                recent_by_state.each do |state, count|
                  li "#{state}: #{count} courses"
                end
              end
            end
          end
        end
        
        column do
          panel "🎯 Priority Actions" do
            total_courses = Course.count
            websites = Course.where("website_url IS NOT NULL AND website_url != '' AND website_url NOT LIKE '%Pending%'").count
            google_data = Course.where("google_place_id IS NOT NULL").count
            sparse_courses = Course.where("(description IS NULL OR LENGTH(description) < 50) AND google_place_id IS NOT NULL").count
            
            ul do
              if (websites.to_f / total_courses) < 0.5
                li style: "color: #dc3545;" do
                  "🔴 Website Collection: #{((websites.to_f / total_courses) * 100).round(1)}% coverage"
                end
              end
              
              if (google_data.to_f / total_courses) < 0.5
                li style: "color: #dc3545;" do
                  "🔴 Google Integration: #{((google_data.to_f / total_courses) * 100).round(1)}% coverage"
                end
              end
              
              if sparse_courses > 1000
                li style: "color: #ffc107;" do
                  "🟡 Enrich #{sparse_courses} courses with Place IDs"
                end
              end
            end
            
            h4 "Quick Actions:"
            ul do
              li link_to "Run Scraping Stats", "#", onclick: "alert('Run: rails courses:scraping_stats')"
              li link_to "View Sparse Courses", "#", onclick: "alert('Run: rails courses:analyze_sparse')"
              li link_to "Discovery Stats", "#", onclick: "alert('Run: rails golf:discovery_stats')"
            end
          end
        end
      end
      
      # State Coverage
      panel "🗺️ State Coverage Analysis" do
        state_stats = Course.joins(:state)
                           .group('states.name')
                           .count
                           .sort_by { |_, count| -count }
        
        columns do
          column do
            h4 "Top 10 States (Most Courses)"
            table do
              thead do
                tr do
                  th "State"
                  th "Courses"
                  th "Coverage"
                end
              end
              tbody do
                state_stats.first(10).each do |state, count|
                  tr do
                    td state
                    td count
                    td do
                      color = count > 500 ? '#28a745' : count > 200 ? '#ffc107' : '#dc3545'
                      span style: "color: #{color};" do
                        count > 500 ? "Excellent" : count > 200 ? "Good" : "Needs Work"
                      end
                    end
                  end
                end
              end
            end
          end
          
          column do
            h4 "States Needing Attention"
            low_coverage = state_stats.select { |_, count| count < 50 }
            
            if low_coverage.any?
              table do
                thead do
                  tr do
                    th "State"
                    th "Courses"
                    th "Status"
                  end
                end
                tbody do
                  low_coverage.each do |state, count|
                    tr do
                      td state
                      td count
                      td style: "color: #dc3545;" do
                        "Needs Discovery"
                      end
                    end
                  end
                end
              end
            else
              p "All states have good coverage! 🎉"
            end
          end
        end
      end
      
      # Data Sources
      panel "📡 Data Sources & Quality" do
        total_courses = Course.count
        google_imported = Course.where("notes LIKE ?", "%Google Places API%").count
        manually_added = total_courses - google_imported
        
        columns do
          column do
            h4 "Data Sources"
            ul do
              li "Google Places API: #{google_imported} (#{((google_imported.to_f / total_courses) * 100).round(1)}%)"
              li "Other Sources: #{manually_added} (#{((manually_added.to_f / total_courses) * 100).round(1)}%)"
            end
          end
          
          column do
            h4 "Quality Metrics"
            phone_coverage = Course.where("phone IS NOT NULL AND phone != ''").count
            email_coverage = Course.where("email IS NOT NULL AND email != ''").count
            
            ul do
              li "Phone Numbers: #{((phone_coverage.to_f / total_courses) * 100).round(1)}%"
              li "Email Addresses: #{((email_coverage.to_f / total_courses) * 100).round(1)}%"
              li "Google Ratings: #{Course.where("google_rating IS NOT NULL").count} courses"
              li "Review Counts: #{Course.where("google_reviews_count IS NOT NULL AND google_reviews_count > 0").count} courses"
            end
          end
        end
      end
    end
  end # content
end
