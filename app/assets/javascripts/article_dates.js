// ---------------------------------------------------------------------------
// Graph support for the ArticleDates results page
google.load('visualization', '1.0', {'packages':['corechart','table']});

function createArticleDatesGraph() {
  // Get the elements we need
  var dataContainer = $('.article_dates_data');
  var percentContainer = $('.article_dates_percent');
  var graphContainer = $('.article_dates_graph');
  var tableContainer = $('.article_dates_table');
  if (graphContainer.length === 0 || dataContainer.length === 0 ||
      percentContainer.length === 0 || tableContainer.length === 0)
    return;

  // Make a DataTable object
  var data = new google.visualization.DataTable();
  var rows = $.parseJSON(dataContainer.html());
  var percent = percentContainer.html() == 'true';

  data.addColumn('number', I18n.t('activemodel.attributes.document.year'));
  if (percent) {
    data.addColumn('number', I18n.t('jobs.analysis.article_dates.fraction_column'));
  } else {
    data.addColumn('number', I18n.t('jobs.analysis.article_dates.number_column'));
  }
  data.addRows(rows);

  // Make the line chart object
  var w = $(window).width();
  if (w > 750) {
    w = 750;
  }

  var h;
  if (w > 480) {
    h = 480;
  } else {
    h = w;
  }

  var options = { width: w, height: h,
                  legend: { position: 'none' },
                  hAxis: { format: '####',
                           title: I18n.t('activemodel.attributes.document.year') },
                  vAxis: { title: I18n.t('jobs.analysis.article_dates.number_column') },
                  pointSize: 3 };
  if (percent) {
    options.vAxis.format = '###%';
    options.vAxis.title = I18n.t('jobs.analysis.article_dates.percent_column');
  }

  var chart = new google.visualization.LineChart(graphContainer[0]);
  chart.draw(data, options);

  graphContainer.trigger('updatelayout');

  // Make a pretty table object
  var table = new google.visualization.Table(tableContainer[0]);
  table.draw(data, { page: true, pageSize: 20, sortColumn: 0, width: '20em' });
}

$(createArticleDatesGraph);
