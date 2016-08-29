$(function () {

  var title = $('#container').data('title');
  var sp = $('#container').data('sprint-period');
  var il = $('#container').data('ideal');
  var ct = $('#container').data('remain-times');
  var at = $('#container').data('additional-times');
  var tet = $('#container').data('total-estimated-times');

  $('#container').highcharts({
    title: {
      text: title,
      x: -20 //center
    },
    xAxis: {
      categories: sp
      },
    yAxis: {
      title: {
        text: "時間",
      }
    },
    tooltip: {
      valueSuffix: 'h'
    },
    legend: {
      layout: 'vertical',
      align: 'right',
      verticalAlign: 'middle',
      borderWidth: 0
    },
    series: [{
      type: 'column',
      name: '追加時間',
      color: '#FF0000',
      dataLabels: {
        enabled: true
      },
      data: eval(at)
    },
    {
      name: '理想',
      lineWidth: 3,
      data: eval(il)
    }, {
      name: '残時間',
      lineWidth: 3,
      dataLabels: {
        enabled: true
      },
      data: eval(ct)
    }, {
      name: '総時間',
      lineWidth: 3,
      dataLabels: {
        enabled: true
      },
      data: eval(tet)
    }]
  });
});
