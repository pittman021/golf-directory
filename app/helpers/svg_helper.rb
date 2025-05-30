module SvgHelper
  def svg_icon(name, options = {})
    # Default options
    default_options = {
      class: "w-4 h-4",
      role: "img",
      "aria-hidden": "true"
    }
    
    # Merge with provided options
    svg_options = default_options.merge(options)
    
    # Try to load the SVG file
    svg_path = Rails.root.join("app", "assets", "images", "icons", "#{name}.svg")
    
    if File.exist?(svg_path)
      svg_content = File.read(svg_path)
      
      # Parse the SVG to add classes and attributes
      doc = Nokogiri::HTML::DocumentFragment.parse(svg_content)
      svg_element = doc.at_css('svg')
      
      if svg_element
        # Add/merge classes
        existing_class = svg_element['class'] || ''
        new_class = [existing_class, svg_options[:class]].join(' ').strip
        svg_element['class'] = new_class unless new_class.empty?
        
        # Add other attributes
        svg_options.except(:class).each do |key, value|
          svg_element[key.to_s] = value
        end
        
        doc.to_html.html_safe
      else
        # Fallback if SVG parsing fails
        content_tag(:span, "⛳", class: svg_options[:class])
      end
    else
      # Fallback if file doesn't exist
      content_tag(:span, "⛳", class: svg_options[:class])
    end
  end
  
  def course_type_icon(course_type, options = {})
    icon_name = case course_type&.downcase
                when 'public'
                  'golf-public'
                when 'private'
                  'golf-private'
                when 'resort', 'semi-private'
                  'golf-resort'
                else
                  'golf-course'
                end
    
    svg_icon(icon_name, options)
  end
end 