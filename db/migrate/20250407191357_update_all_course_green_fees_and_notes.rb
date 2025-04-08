class UpdateAllCourseGreenFeesAndNotes < ActiveRecord::Migration[7.2]
  def up
    # Create a hash of course updates
    course_updates = {
      "Pebble Beach Golf Links" => {
        green_fee: 575,
        notes: "Iconic oceanside links featuring stunning clifftop holes. Home to multiple U.S. Opens. Signature 7th hole is one of golf's most photographed par-3s.",
        layout_tags: ['ocean views', 'clifftop holes', 'links style', 'water holes']
      },
      "Spyglass Hill Golf Course" => {
        green_fee: 395,
        notes: "Robert Trent Jones Sr. design combining coastal dunes and forest. First five holes offer ocean views before heading into the Del Monte Forest.",
        layout_tags: ['ocean views', 'forest', 'elevation changes', 'dog legs']
      },
      "Pine Beach East" => {
        green_fee: 89,
        notes: "Classic Minnesota resort course with scenic Gull Lake views. Tree-lined fairways and strategic bunkering make for an engaging round.",
        layout_tags: ['lake views', 'tree lined', 'bunkers', 'traditional']
      },
      "Pine Beach West" => {
        green_fee: 59,
        notes: "Family-friendly resort course featuring gentle elevation changes and forgiving fairways. Great value for casual golfers.",
        layout_tags: ['lake views', 'wide fairways', 'beginner friendly', 'traditional']
      },
      "TPC Myrtle Beach" => {
        green_fee: 189,
        notes: "Tom Fazio design with tour-caliber conditions. Challenging layout with water features on 10 holes. Excellent practice facilities.",
        layout_tags: ['water holes', 'tree lined', 'dog legs', 'tournament venue']
      },
      "Dunes Golf and Beach Club" => {
        green_fee: 349,
        notes: "Historic Robert Trent Jones Sr. design with the famous 'Waterloo' par-5 13th hole wrapping around Lake Singleton. Multiple PGA Tour host.",
        layout_tags: ['ocean views', 'water holes', 'traditional', 'tournament venue']
      },
      "Caledonia Golf & Fish Club" => {
        green_fee: 199,
        notes: "Mike Strantz masterpiece built on a historic rice plantation. Live oaks draped with Spanish moss frame the fairways. Stunning finishing hole.",
        layout_tags: ['water holes', 'tree lined', 'lowcountry', 'traditional']
      },
      "Barefoot Resort - Love Course" => {
        green_fee: 169,
        notes: "Davis Love III design featuring recreated ruins of an old plantation home. Wide fairways and challenging green complexes. Lowcountry charm.",
        layout_tags: ['wide fairways', 'water holes', 'lowcountry', 'resort style']
      },
      "Pine Lakes Country Club" => {
        green_fee: 129,
        notes: "Myrtle Beach's first golf course, opened in 1927. Known as 'The Granddaddy'. Recently restored to preserve its historic Scottish-American design.",
        layout_tags: ['traditional', 'tree lined', 'historic', 'water holes']
      },
      "Bandon Dunes" => {
        green_fee: 395,
        notes: "True links golf on the Oregon coast. David McLay Kidd's first American design. Stunning ocean views from every hole. Walking only.",
        layout_tags: ['ocean views', 'links style', 'dunes', 'walking only']
      },
      "Sand Valley" => {
        green_fee: 245,
        notes: "Coore & Crenshaw design in central Wisconsin. Dramatic sand dunes and ridges create a links-like experience in America's heartland.",
        layout_tags: ['links style', 'dunes', 'wide fairways', 'walking only']
      },
      "Arcadia Bluffs" => {
        green_fee: 215,
        notes: "Dramatic cliffside course overlooking Lake Michigan. Scottish links-style design with massive dunes and challenging winds.",
        layout_tags: ['lake views', 'links style', 'clifftop holes', 'dunes']
      }
    }

    # Update each course
    course_updates.each do |course_name, updates|
      course = Course.find_by(name: course_name)
      if course
        course.update!(
          green_fee: updates[:green_fee],
          notes: updates[:notes],
          layout_tags: updates[:layout_tags]
        )
        puts "Updated #{course_name}"
      end
    end

    # For any courses not specifically listed above, set reasonable defaults based on their green_fee_range
    Course.where(green_fee: nil).each do |course|
      default_fee = case course.green_fee_range
        when '$' then rand(45..60)
        when '$$' then rand(80..150)
        when '$$$' then rand(151..300)
        when '$$$$' then rand(301..500)
        else 100
      end

      default_notes = "#{course.number_of_holes}-hole #{course.course_type.humanize.downcase} course. " +
                     "Playing at #{course.yardage} yards with a par of #{course.par}. " +
                     course.description

      # Set default layout tags based on course type
      default_tags = case course.course_type
        when 'public_course'
          ['traditional', 'public access', 'walking friendly']
        when 'private_course'
          ['traditional', 'private club', 'exclusive']
        when 'resort_course'
          ['resort style', 'vacation golf', 'amenities']
        else
          ['traditional', 'golf course']
      end

      course.update!(
        green_fee: default_fee,
        notes: default_notes,
        layout_tags: default_tags
      )
      puts "Set default values for #{course.name}"
    end
  end

  def down
    Course.update_all(green_fee: nil, notes: nil, layout_tags: [])
  end
end
