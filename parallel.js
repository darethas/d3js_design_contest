//function chart(width, height, parWidth, parHeight) {
//    return function() {
var columns = 10;

var width = 300,
    height = 300,
    parWidth = 700,
    parHeight = 300;

var color = d3.scale.ordinal()
    .domain(["A", "G", "N", "P", "K", "Q", "R"])
    .range(colorbrewer.Paired[7]);

var line = d3.svg.line()
    .x(function(d) { return d.x; })
    .y(function(d) { return d.y; });

var axis = d3.svg.axis().orient("left");

var Calories = d3.scale.linear().domain([50,160]).range([parHeight-30,30]),
    Protein = d3.scale.linear().domain([0,6]).range([30,parHeight-30]),
    Fat = d3.scale.linear().domain([0,5]).range([30,parHeight-30]),
    Sodium = d3.scale.linear().domain([0,325]).range([30,parHeight-30]),
    Fiber = d3.scale.linear().domain([0,15]).range([30,parHeight-30]),
    Carbohydrates = d3.scale.linear().domain([0,24]).range([30,parHeight-30]),
    Sugars = d3.scale.linear().domain([0,15]).range([30,parHeight-30]),
    Potassium = d3.scale.linear().domain([0,330]).range([30,parHeight-30]),
    Vitamins = d3.scale.linear().domain([0,100]).range([30,parHeight-30]),
    Manufacturer = d3.scale.ordinal().domain(["A", "G", "N", "P", "K", "Q", "R"]).rangePoints([30, parHeight - 30]);

var force = d3.layout.force()
    .charge(-120)
    .linkDistance(30)
    .friction(0.8)
    .size([width, height]);

var right = d3.select("#chart-right").append("svg")
    .attr("width", width)
    .attr("height", height);

var left = d3.select("#chart-left").append("svg")
    .attr("width", parWidth)
    .attr("height", parWidth);

d3.json("cereals.json", function(json) {
    force
        .nodes(json.nodes)
        .links(json.links)
        .start();

    var lines = left.selectAll("path.node")
        .data(json.nodes, function(d) { return d.name })
        .enter().append("path")
        .attr("class", "node")
        .attr("name", function(d) {return d.name})
        .style("stroke-width", 1)
        .style("stroke", function(d) { return color(d.Manufacturer); })
        .on("mouseover", function() {
            d3.selectAll("path.node")
                .data(d3.select(this).data())
                .style("stroke-width", 10)
                .style("stroke", function(d) { return color(d.Manufacturer); });

        })
        .on("mouseout", function() {
            d3.selectAll("path.node")
                .data(d3.select(this).data())
                .style("stroke-width", null)
                .style("stroke", function(d) { return color(d.Manufacturer); });
        })


    // Add an axis and title.
    var g = left.selectAll("g.trait")
        .data(['Manufacturer', 'Calories','Protein', 'Fat', 'Sodium', 'Fiber', 'Carbohydrates', 'Sugars', 'Potassium', 'Vitamins'])
        .enter().append("svg:g")
        .attr("class", "trait")
        .attr("transform", function(d,i) {
            return "translate(" + (40+(parWidth/columns)*i) + ")";
        })
    g.append("svg:g")
        .attr("class", "axis")
        .each(function(d) { d3.select(this).call(axis.scale(window[d])); })
        .append("svg:text")
        .attr("class", "title")
        .attr("text-anchor", "middle")
        .attr("y", 12)
        .text(String);

    var link = right.selectAll("line.link")
        .data(json.links)
        .enter().append("line")
        .attr("class", "link")
        .style("stroke-width", function(d) { return Math.sqrt(d.value); });

    var circles = right.selectAll("circle.node")
        .data(json.nodes, function(d) { return d.name })
        .enter().append("circle")
        .attr("class", "node")
        .attr("r", 5)
        .attr("name", function(d) {return d.name})
        .style("fill", function(d) { return color(d.Manufacturer); })
        .on("mouseover", function() {
            d3.selectAll("path.node")
                .data(d3.select(this).data())
                .style("stroke-width", 10)
                .style("stroke", function(d) { return color(d.Manufacturer); });
            d3.select(this).attr('r', 12);
        })
        .on("mouseout", function() {
            d3.selectAll("path.node")
                .data(d3.select(this).data())
                .style("stroke-width", null)
                .style("stroke", function(d) { return color(d.Manufacturer); });
            d3.select(this).attr('r', 5);
        })
        .call(force.drag);

    var circles = right.selectAll("circle.node")
        .data(json.nodes, function(d) { return d.name })

    circles.append("title")
        .text(function(d) { return d.name; });

//    lines.on("mouseover", function() {
//        d3.selectAll("path.node")
//            .data(d3.select(this).data())
//            .style("stroke-width", 7)
//            .style("stroke", function(d) { return color(d.Manufacturer); });
//        right.selectAll("circle.node").each( function(d, i){
//            //if(d.name == d3.select(this.firstChild.data){
//                d3.select(this.firstChild).attr("r",12);
//            //}
//        });
//    })
//        .on("mouseout", function() {
//            d3.selectAll("path.node")
//                .data(d3.select(this).data())
//                .style("stroke-width", null)
//                .style("stroke", function(d) { return color(d.Manufacturer); });
//            right.selectAll("circle.node").attr('r', 5);
//        });

    force.on("tick", function() {
        lines.attr("d", function(d,i) {
            return line([
                {x:40+(parWidth/columns)*0, y:Manufacturer(d.Manufacturer)},
                {x:40+(parWidth/columns)*1, y:Calories(Math.abs(d.Calories))},
                {x:40+(parWidth/columns)*2, y:Protein(Math.abs(d.Protein))},
                {x:40+(parWidth/columns)*3, y:Fat(Math.abs(d.Fat))},
                {x:40+(parWidth/columns)*4, y:Sodium(Math.abs(d.Sodium))},
                {x:40+(parWidth/columns)*5, y:Fiber(Math.abs(d.Fiber))},
                {x:40+(parWidth/columns)*6, y:Carbohydrates(Math.abs(d.Carbohydrates))},
                {x:40+(parWidth/columns)*7, y:Sugars(Math.abs(d.Sugars))},
                {x:40+(parWidth/columns)*8, y:Potassium(Math.abs(d.Potassium))},
                {x:40+(parWidth/columns)*9, y:Vitamins(Math.abs(d.Vitamins))}
            ]);
        });
        link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; })
        circles.attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });
    });
});
//    }
//}