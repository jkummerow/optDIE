function createChart(chart_id, data) {
    var ctx = $("#"+chart_id);
    var labels = [];
    for (var i=1; i <= data.length; i++) {
        labels.push(i);
    }
    var myChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                data: data,
                lineTension: 0.3,
                backgroundColor: 'transparent',
                borderColor: '#007bff',
                borderWidth: 2,
                pointBackgroundColor: '#007bff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
            xAxes: [{
                display: true,
                scaleLabel: {
                    display: true,
                    labelString: 'Stützstellen'
                }
            }],
            yAxes: [{
                display: true,
                scaleLabel: {
                    display: true,
                    labelString: ''
                },
                ticks: {
                    beginAtZero: false,
                    callback: function (value) {
                        return value.toExponential()
                    }
                }
            }]
            },
            legend: {
            display: false
            },
            tooltips: {
                callbacks: {
                    label: function(tooltipItem, data) {
                        var label = data.datasets[tooltipItem.datasetIndex].label || '';
                        if (label) {
                            label += ': ';
                        }
                        label += tooltipItem.yLabel.toExponential();
                        return label;
                    }
                }
            }
        }
    });
    return myChart;
}

function updateChart(chart, data) {
    var labels = [];
    for (var i=1; i <= data.length; i++) {
        labels.push(i);
    }
    chart.data.labels = labels;
    chart.data.datasets.forEach((dataset) => {
        dataset.data = data;
    });
    chart.update();
}

function createChartDS(chart_id, data) {
    var ctx = $("#"+chart_id);
    var data_f = [];
    for (var i=1; i <= data.length; i++) {
        data_f.push({x: i, y: data[i]});
    }
    var myData = [
        {
            values: data_f,
            key: 'ms'
        }
    ];
    nv.addGraph(function () {
        var chart = nv.models.lineChart()
            .useInteractiveGuideline(false)
            .showLegend(false)
        ;
        //axis
        chart.xAxis
            .axisLabel('Stützstellen')
            .tickFormat(d3.format(',r'))
        ;
        chart.yAxis
            .axisLabel('Massenstrom [kg/s]')
            //.tickFormat(d3.format('.02f'))
        ;
        //render
        d3.select('#'+chart_id)
            .datum(myData)
            .transition().duration(500)
            .call(chart)
        ;
        //re-render callback
        nv.utils.windowResize(chart.update);
        return chart;
    });

}

function createChartDIM(chart_id, data, lbl=['', '']) {
    var ctx = $("#"+chart_id);

    var myChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: data[0],
            datasets: [{
                data: data[1],
                lineTension: 0.3,
                backgroundColor: 'transparent',
                borderColor: '#007bff',
                borderWidth: 2,
                pointBackgroundColor: '#007bff',
                type: 'line',
                pointRadius: 1,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
            xAxes: [{
                distribution: 'series',
                ticks: {
                    source: 'labels'
                },
                display: true,
                scaleLabel: {
                    display: true,
                    labelString: lbl[0]
                }
            }],
            yAxes: [{
                display: true,
                scaleLabel: {
                    display: true,
                    labelString: lbl[1]
                },
                ticks: {
                    beginAtZero: false,
                }
            }]
            },
            legend: {
            display: false
            },

        }
    });
    return myChart;
}