
class BubbleChart
  constructor: (data) ->
    @data = data
    @width = 940
    @height = 600
    @colSpace = 940/7 #Space between manufacturer clusters
    @txtSpace = 940/7 * 2 #Space between manufacturer column labels

    @tooltip = CustomTooltip("cereal_tooltip", 240)

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2}
    #{"A": @width/2 - (@width/7)*3, "G": @width/2 - (@width/7)*2, "N": @width/2 - @width/7, "P": @width / 2, "K": @width / 2 + (@width/7),"Q": @width / 2 + (@width/7)*2, "R": @width / 2 + (@width/7)*3}
    @manufacturer_centers = {
      "A": {x: @width/2 - @colSpace*1.5, y: @height / 2},
      "G": {x: @width/2 - @colSpace*1, y: @height / 2},
      "N": {x: @width/2 - @colSpace*0.5, y: @height / 2},
      "P": {x: @width / 2, y: @height / 2},
      "K": {x: @width / 2 + @colSpace*0.5, y: @height / 2},
      "Q": {x: @width / 2 + @colSpace*1, y: @height / 2},
      "R": {x: @width / 2 + @colSpace*1.5, y: @height / 2}
    }

    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.01
    @damper = 0.1

    # these will be set in create_nodes and create_vis
    @vis = null
    @nodes = []
    @force = null
    @circles = null

    # nice looking colors - no reason to buck the trend


    @fill_color = d3.scale.ordinal()
      .domain(["A", "G","N", "P", "K", "Q", "R"])
      .range(colorbrewer.Greens[6]);

    # use the max total_amount in the data as the max in the scale's domain
    max_amount = d3.max(@data, (d) -> parseInt(d.Calories))
    @radius_scale = d3.scale.pow().exponent(3.5).domain([0, max_amount]).range([2, 85])

    @fill_color_calories = d3.scale.linear()
      .domain([0, max_amount])
      .range(colorbrewer.Reds[9])
    
    this.create_nodes()
    this.create_vis()

  # create node objects from original data
  # that will serve as the data behind each
  # bubble in the vis, then add each node
  # to @nodes to be used later
  create_nodes: () =>
    @data.forEach (d) =>
      node = {
        id: d.id
        radius: @radius_scale(parseInt(d.Calories))
        value: d.Calories
        name: d.Cereal
        manufacturer: d.Manufacturer
        type: d.Type
        protein: d.Protein
        fat: d.Fat
        sodium: d.Sodium
        fiber: d.Fiber
        carbs: d.Carbohydrates
        sugars: d.Sugars
        shelf: d.Shelf
        potassium: d.Potassium
        vitamins: d.Vitamins
        weight: d.Weight
        cups: d.Cups
        x: Math.random() * 900
        y: Math.random() * 800
      }
      @nodes.push node

    @nodes.sort (a,b) -> b.value - a.value


  # create svg at #vis and then 
  # create circle representation for each node
  create_vis: () =>
    @vis = d3.select("#vis").append("svg")
      .attr("width", @width)
      .attr("height", @height)
      .attr("id", "svg_vis")

    @circles = @vis.selectAll("circle")
      .data(@nodes, (d) -> d.id)

    # used because we need 'this' in the 
    # mouse callbacks
    that = this

    # radius will be set to 0 initially.
    # see transition below
    @circles.enter().append("circle")
      .attr("r", 0)
      .attr("fill", (d) => @fill_color(d.manufacturer))
      .attr("stroke-width", 2)
      .attr("stroke", (d) => d3.rgb(@fill_color(d.manufacturer)).darker())
      .attr("id", (d) -> "bubble_#{d.id}")
      .on("mouseover", (d,i) -> that.show_details(d,i,this))
      .on("mouseout", (d,i) -> that.hide_details(d,i,this))

    # Fancy transition to make bubbles appear, ending with the
    # correct radius
    @circles.transition().duration(2000).attr("r", (d) -> d.radius)


  # Charge function that is called for each node.
  # Charge is proportional to the diameter of the
  # circle (which is stored in the radius attribute
  # of the circle's associated data.
  # This is done to allow for accurate collision 
  # detection with nodes of different sizes.
  # Charge is negative because we want nodes to 
  # repel.
  # Dividing by 8 scales down the charge to be
  # appropriate for the visualization dimensions.
  charge: (d) ->
    -Math.pow(d.radius, 2.0) / 8

  # Starts up the force layout with
  # the default values
  start: () =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])

  # Sets up force layout to display
  # all nodes in one circle.
  display_group_all: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_manufacturers()

  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
      d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

  # sets the display of bubbles to be separated
  # into each year. Does this by calling move_towards_year
  display_by_manufacturer: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_manufacturer(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.display_manufacturers()

  # move all circles to their associated @year_centers 
  move_towards_manufacturer: (alpha) =>
    (d) =>
      target = @manufacturer_centers[d.manufacturer]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1

  # Method to display manufacturer titles ["A", "G", "N", "P", "K", "Q", "R"]
  display_manufacturers: () =>
    manufacturers_x = {"A": @width/2 - @txtSpace*1.5, "G": @width/2 - @txtSpace*1, "N": @width/2 - @txtSpace*0.5, "P": @width / 2, "K": @width / 2 + @txtSpace*0.5,"Q": @width / 2 + @txtSpace*1, "R": @width / 2 + @txtSpace*1.5}
    manufacturers_data = d3.keys(manufacturers_x)
    manufacturers = @vis.selectAll(".manufacturers")
      .data(manufacturers_data)

    manufacturers.enter().append("text")
      .attr("class", "manufacturers")
      #.attr("font-weight", "bold")
      .attr("x", (d) => manufacturers_x[d] )
      .attr("y", 40)
      .attr("text-anchor", "middle")
      .text((d) -> d)

  # Method to hide year titiles
  hide_manufacturers: () =>
    manufacturers = @vis.selectAll(".manufacturers").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "black")
    content = "<span class=\"name\">Cereal:</span><span class=\"value\"> #{data.name}</span><br/>"
    content +="<span class=\"name\">Calories:</span><span class=\"value\"> #{addCommas(data.value)}</span><br/>"
    content +="<span class=\"name\">Manufacturer:</span><span class=\"value\"> #{data.manufacturer}</span><br/>"
    content +="<span class=\"name\">Type:</span><span class=\"value\"> #{data.type}</span><br/>"
    content +="<span class=\"name\">Protein:</span><span class=\"value\"> #{data.protein}</span><br/>"
    content +="<span class=\"name\">Fat:</span><span class=\"value\"> #{data.fat}</span><br/>"
    content +="<span class=\"name\">Sodium:</span><span class=\"value\"> #{data.sodium}</span><br/>"
    content +="<span class=\"name\">Fiber:</span><span class=\"value\"> #{data.fiber}</span><br/>"
    content +="<span class=\"name\">Carbohydrates:</span><span class=\"value\"> #{data.carbs}</span><br/>"
    content +="<span class=\"name\">Sugars:</span><span class=\"value\"> #{data.sugars}</span><br/>"
    content +="<span class=\"name\">Shelf:</span><span class=\"value\"> #{data.shelf}</span><br/>"
    content +="<span class=\"name\">Potassium:</span><span class=\"value\"> #{data.potassium}</span><br/>"
    content +="<span class=\"name\">Vitamins:</span><span class=\"value\"> #{data.vitamins}</span><br/>"
    content +="<span class=\"name\">Weight:</span><span class=\"value\"> #{data.weight}</span><br/>"
    content +="<span class=\"name\">Cups:</span><span class=\"value\"> #{data.cups}</span>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.manufacturer)).darker())
    @tooltip.hideTooltip()


root = exports ? this

$ ->
  chart = null

  render_vis = (csv) ->
    chart = new BubbleChart csv
    chart.start()
    root.display_all()
  root.display_all = () =>
    chart.display_group_all()
  root.display_manufacturers = () =>
    chart.display_by_manufacturer()
  root.toggle_view = (view_type) =>
    if view_type == 'manufacturer'
      root.display_manufacturers()
    else
      root.display_all()

  d3.csv "data/a1-cereals.csv", render_vis
