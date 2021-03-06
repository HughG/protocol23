#! /opt/local/bin/ruby1.9

require "rexml/document"
require File.expand_path(File.dirname(__FILE__)) + "/yaml2x.rb"

include REXML

# TODO 2012-04-13 HUGR: Add fallback to no layout if layout is broken.
# Highlight by drawing boxes differently?
#
# TODO 2012-04-13 HUGR: Add error-checking for Charms that aren't in any
# layout, or appear more than once, or layouts with unknown IDs.
#
# TODO 2012-04-13 HUGR: Add error checking for deps that can't be auto-routed.
#
# TODO 2012-04-13 HUGR: Add manually-routed arrows.
#
# TODO 2012-04-13 HUGR: Add error checking for manual routing that doesn't
# match deps.
#
# TODO 2012-04-13 HUGR: Allow for multiple layouts.
#
# TODO 2012-04-13 HUGR: Auto-place multiple layouts?

# Although the body text in the Exalted books is 10pt on 12pt, the Charm boxes
# seem to use about 9pt on 11pt.
PT_PER_MM = 25.4/72
FONT_SIZE_IN_MM = (9 * PT_PER_MM)
LINE_HEIGHT_IN_MM = (11 * PT_PER_MM)

CB_WIDTH = 49 # 49mm
CB_HEIGHT = 25 # 25mm
CB_HORIZ_GAP = 8 # 8mm
CB_VERT_GAP = 9.5 # 9.5mm
CB_COLUMNS = 3
OUTLINE_POINTS = [
  [0,2], [9,2], [7,0], [42,0], [40,2], [49,2],
  [49,23], [40,23], [42,25], [7,25], [9,23], [0,23]
]

ARROW_POINTS = [
  [ [0,2], [24.5, 0], [49, 2] ],
  [ [0, 12.5], nil, [49, 12.5] ],
  [ [0, 23], [24.5, 25], [49, 23] ]
]

def make_style(hash)
  hash.map {|k,v| "#{k}: #{v}"}.join "; "
end

def make_path(arr)
  arr.map {|c| "#{c[0]},#{c[1]}"}.join " "
end

def offset_points(x, y, points)
  points.map {|p| [p[0] + x, p[1] + y]}
end

CB_STYLE = make_style(
  "fill" => "#fae88a",
  # "fill-opacity" => "0", # transparent
  "stroke" => "#b7985b",
  "stroke-linejoin" => "round",
  "stroke-width" => "0.3",
)

def draw_outline(box, x, y)
  points = offset_points(x, y, OUTLINE_POINTS)
  poly = box.add_element "polygon", {
    "style" => CB_STYLE,
    "points" => make_path(points)
  }
end

FIRST_DOT_X = 12.5 # mm
DOT_SPACING = 6 # mm
DOT_INSET = 2.5 # mm

def draw_dot(
    box,
    x,
    y,
    is_top,
    index,
    is_filled,
    filled_style,
    empty_style
    )
  style = is_filled ? filled_style : empty_style
  y_pos = (is_top ? DOT_INSET : (CB_HEIGHT - DOT_INSET)) + y
  r = is_filled ? 1.75 : 1.5
  box.add_element "circle", {
    "style" => style,
    "cx" => FIRST_DOT_X + (index * DOT_SPACING) + x,
    "cy" => y_pos,
    "r" => r,
  }
end

EMPTY_DOT_STYLE = make_style(
  "fill" => "#3e494d",
  "stroke" => "#2a2a11",
  "stroke-width" => "0.3",
  )
ESSENCE_DOT_STYLE = make_style(
  "fill" => "#ffff00",
  "stroke" => "#dcc593",
  "stroke-width" => "0.3",
  )
TRAIT_DOT_STYLE = make_style(
  "fill" => "#ff0000",
  "stroke" => "#dc9393",
  "stroke-width" => "0.3",
  )

def draw_dots(box, x, y, essence_rating, trait_rating)
  for d in 0..4
    draw_dot(
      box, x, y,
      true, d, d < essence_rating,
      ESSENCE_DOT_STYLE, EMPTY_DOT_STYLE
      )
    draw_dot(
      box, x, y,
      false, d, d < trait_rating,
      TRAIT_DOT_STYLE, EMPTY_DOT_STYLE
      )
  end
end

def draw_grid(box)
  grid_style = make_style({
    "fill-opacity" => "0",
    "stroke" => "silver",
    "stroke-width" => "0.1",
  })
  grid_style2 = make_style({
    "fill-opacity" => "0",
    "stroke" => "grey",
    "stroke-width" => "0.1",
  })
  for gx in 0..49
    grid1 = box.add_element "line", {
      "style" => (gx % 5 == 0) ? grid_style2 : grid_style,
      "x1" => (gx + x),
      "y1" => (0 + y),
      "x2" => (gx + x),
      "y2" => (CB_HEIGHT + y),
    }
  end
  for gy in 0..25
    grid1 = box.add_element "line", {
      "style" => (gy % 5 == 0) ? grid_style2 : grid_style,
      "x1" => (0 + x),
      "y1" => (gy + y),
      "x2" => (CB_WIDTH + x),
      "y2" => (gy + y),
    }
  end
end

TEXT_STYLE = make_style(
  "fill" => "#000000",
  "text-anchor" => "middle",
  "font-family" => "Libertinage",
  "font-style" => "normal",
  "font-weight" => "500" # Normal
  )

def draw_text(box, x, y, text_lines)
  line_count = text_lines.length
  total_text_height = FONT_SIZE_IN_MM + (LINE_HEIGHT_IN_MM * (line_count - 1))
  # We want to centre the lines of text within the Charm box.
  first_line_top = (CB_HEIGHT - total_text_height) / 2
  # We subtract an extra 1mm as a fudge factor, so that the descenders
  # of the last line effectively aren't included in the centering.
  first_line_offset = first_line_top + FONT_SIZE_IN_MM - 1
  line_offset = first_line_offset

  text = box.add_element "text", {
    "font-size" => FONT_SIZE_IN_MM,
    "style" => TEXT_STYLE,
    "x" => (24.5 + x),
    "y" => (line_offset + y),
  }
  for line in text_lines
    tspan = text.add_element "tspan", {
      "x" => (24.5 + x),
      "y" => (line_offset + y),
    }
    tspan.add Text.new(line, false)
    line_offset += LINE_HEIGHT_IN_MM
  end

end

def draw_charm(box, x, y, charm, trait_name)
  draw_outline(box, x, y)

  if (charm.mins != nil)
    essence_dots = charm.mins["Essence"]
    trait_dots = charm.mins[trait_name]
    draw_dots(box, x, y, essence_dots, trait_dots)
  end

  if (false)
    draw_grid(box)
  end

  text_lines = charm.multi_line_name
  if charm.deps.nil? or charm.deps.empty?
    text_lines.map! {|s| s.upcase}
  end
  # Special magic for the names of Excellencies: replace "--" with ": ".
  text_lines.map! {|s| s.gsub("--", ": ")}
  draw_text(box, x, y, text_lines)
end

ARROW_LINE_STYLE = make_style(
  "stroke" => "black",
  "stroke-width" => "0.75",
#  "stroke-linecap" => "square"
  )

ARROW_HEAD_STYLE = make_style(
  "fill" => "black",
  "stroke" => "none",
  )

def draw_arrow(box, line)
  # line is the line segment from p1 to p2
  x1 = line[0][0]
  y1 = line[0][1]
  x2 = line[1][0]
  y2 = line[1][1]  

  # pd is the vector from p1 to p2
  xd = x2 - x1
  yd = y2 - y1

  line_length = Math.sqrt(xd*xd + yd*yd)

  # pu is the unit (1mm) vector from p1 to p2
  xu = xd / line_length
  yu = yd / line_length
  # pp is perpendicular to pu
  xp = yu
  yp = -xu

  # We want to move the start of the line back a couple of millimetres, 
  # so that the start appears to flow fully into the box.  We also move the
  # end back a little, so it doesn't flow over the end of the arrowhead.
  final_x1 = x1 - 2*xu
  final_y1 = y1 - 2*yu
  final_x2 = x2 - 2*xu
  final_y2 = y2 - 2*yu

  # p_base is the base of the arrowhead, and p_side1 & p_side2 are the sides
  x_base = x2 - 2.5*xu
  y_base = y2 - 2.5*yu
  x_side1 = x2 - 3.5*xu + 1.5*xp
  y_side1 = y2 - 3.5*yu + 1.5*yp
  x_side2 = x2 - 3.5*xu - 1.5*xp
  y_side2 = y2 - 3.5*yu - 1.5*yp

  box.add_element "line", {
    "style" => ARROW_LINE_STYLE,
    "x1" => final_x1,
    "y1" => final_y1,
    "x2" => final_x2,
    "y2" => final_y2,
  }

  points = [
            [x_base, y_base], [x_side1, y_side1], [x2, y2], [x_side2, y_side2]
           ]
  box.add_element "polygon", {
    "style" => ARROW_HEAD_STYLE,
    "points" => make_path(points)
  }

end

def draw_arrows(box, charms, layout)
  cb_rows = layout.grid.length

  # Create reverse mapping from charm name to row/column, for arrows.
  charm_grid_pos = {}
  for row in 0..(cb_rows - 1)
    # TODO 2012-04-13 HUGR: Check for >3 columns
    for col in 0..2
      charm = charms[layout.grid[row][col]]
      next if charm == nil
      charm_grid_pos[charm.id] = [row, col]
    end
  end

  charm_grid_pos.each { |charm_id, dst_pos|
    charm = charms[charm_id]
    if charm.deps != nil
      charm.deps.each { |dep|
        src_pos = charm_grid_pos[dep]
        if not (src_pos and dst_pos) then
          puts "ERROR: #{dep}@#{src_pos} -> #{charm.id}@#{dst_pos}"
        end
        src_to_dst_dir = [
          dst_pos[0] <=> src_pos[0],
          dst_pos[1] <=> src_pos[1]
        ]
        src_to_dst_anchor = [
          src_to_dst_dir[0] + 1,
          src_to_dst_dir[1] + 1
        ]
        dst_to_src_anchor = [
          -src_to_dst_dir[0] + 1,
          -src_to_dst_dir[1] + 1
        ]
        #puts "  #{dep}/#{src_to_dst_anchor} -> #{charm.id}/#{dst_to_src_anchor}"
        src_point = ARROW_POINTS[src_to_dst_anchor[0]][src_to_dst_anchor[1]]
        dst_point = ARROW_POINTS[dst_to_src_anchor[0]][dst_to_src_anchor[1]]
        #puts "  #{dep}/#{src_point} -> #{charm.id}/#{dst_point}"

        src_row = src_pos[0]
        src_col = src_pos[1]
        src_x = src_col * (CB_WIDTH + CB_HORIZ_GAP)
        src_y = src_row * (CB_HEIGHT + CB_VERT_GAP)

        dst_row = dst_pos[0]
        dst_col = dst_pos[1]
        dst_x = dst_col * (CB_WIDTH + CB_HORIZ_GAP)
        dst_y = dst_row * (CB_HEIGHT + CB_VERT_GAP)

        draw_arrow(box, [
                         [src_point[0] + src_x, src_point[1] + src_y],
                         [dst_point[0] + dst_x, dst_point[1] + dst_y]
                        ])
      }
    end
  }
end

def draw_layout(group, charms, layout, outfilename)
  File.open(outfilename, "w") { |outfile|
    raw_charms = charms.values
    return if (layout == nil or layout.grid == nil)
    cb_rows = layout.grid.length

    doc = Document.new
    doc << XMLDecl.new("1.0", "utf-8")
    doc << DocType.new("svg", 'PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/PR-SVG-20010719/DTD/svg10.dtd"')
    # Add 1mm to height and width to avoid clipping of right-/bottom-most pixels
    width = (CB_WIDTH * CB_COLUMNS) + (CB_HORIZ_GAP * (CB_COLUMNS - 1)) + 1
    height = (CB_HEIGHT * cb_rows) + (CB_VERT_GAP * (cb_rows - 1)) + 1
    view_box = [-1, -1, width + 1, height + 1]
    svg = doc.add_element "svg", {
      "width" => (width + 2).to_s + "mm",
      "height" => (height + 2).to_s + "mm",
      "viewBox" => view_box.join(" ")
    }
    svg.add_namespace("http://www.w3.org/2000/svg")
    svg.add_namespace("xlink", "http://www.w3.org/1999/xlink")
    box = svg.add_element "g", {
    }

    draw_arrows(box, charms, layout)

    for row in 0..(cb_rows - 1)
      # TODO 2012-04-13 HUGR: Check for >3 columns
      for col in 0..2
        charm_id = layout.grid[row][col]
        next if charm_id == nil
        charm = charms[charm_id]
        if charm == nil
          $stderr << "No charm matching id #{charm_id}\n"
          exit(-1)
        end

        x = col * (CB_WIDTH + CB_HORIZ_GAP)
        y = row * (CB_HEIGHT + CB_VERT_GAP)
        draw_charm(box, x, y, charm, group.trait)
      end
    end

    doc.write(outfile, 1, true)
  }
end

if __FILE__ == $PROGRAM_NAME
#  puts $PROGRAM_NAME + "..."

  filename = $*[0]
  outfilename = $*[1]

  matches = /([0-9])_.*/.match(outfilename)
  division = matches[1].to_i

  process_file(filename) { |group, charms, layouts|
    if layouts.length == 0
      $stderr << "No layout for #{group.name}\n"
    elsif layouts.length > 1
      p layouts
      $stderr << "Can only handle 1 layout for now\n"
      exit(-1)
    else
      draw_layout(group, charms, layouts[0], outfilename)
    end
  }
end
