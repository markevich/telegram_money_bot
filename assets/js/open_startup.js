import { _adapters, Chart, LineController, Line, BarController, Rectangle, Point, LinearScale, Tooltip, TimeScale, Legend, Title } from "chart.js"
import { ru } from 'date-fns/locale'
import dateAdatper from './chart_date_fns';

Chart.register(LineController, Line, BarController, Rectangle, Point, LinearScale, TimeScale, Tooltip, Legend, Title)
_adapters._date.override(dateAdatper);

export default {
  profits() { return JSON.parse(this.el.dataset.profits) },
  popularCategories() { return JSON.parse(this.el.dataset.popularCategories) },
  mostExpensiveCategories() { return JSON.parse(this.el.dataset.mostExpensiveCategories) },
  activeUsers() { return JSON.parse(this.el.dataset.activeUsers)},
  users() { return JSON.parse(this.el.dataset.users)},
  transactions() { return JSON.parse(this.el.dataset.transactions)},
  colors() {
    const colors = {
      blue: "rgb(54, 162, 235)",
      yellow: "rgb(249, 231, 159)",
      green: "rgb(75, 192, 192)",
      red: "rgb(255, 99, 132)",
      purple: "rgb(108, 52, 131)",
      grey: "rgb(201, 203, 207)",
      darkRed: "rgb(110, 44, 0)",
      darkBlue: "rgb(28, 40, 51)",
      darkGreen: "rgb(0, 131, 143)"
    }

    return Object.entries(colors).map(([k, v]) => v)
  },
  createUsersChart() {
    const ctx = document.getElementById('data-users');
    const colors = this.colors();

    var config = {
      type: 'line',
      data: {
        datasets: [
          {
            fill: false,
            label: 'Пользователи.',
            borderColor: colors[0],
            backgroundColor: colors[0],
            data: this.users().map((u) => {
              return {
                x: u.date,
                y: u.users_count,
              }
            }),
          },
          {
            fill: false,
            label: 'Активные пользователи.',
            borderColor: colors[1],
            backgroundColor: colors[1],
            data: this.activeUsers().map((u) => {
              return {
                x: u.date,
                y: u.users_count,
              }
            }),
          },
        ]
      },
      options: {
        title: {
          display: true,
          text: "Пользователи"
        },
        legend: {
          display: true
        },
        responsive: true,
        maintainAspectRatio: false,
        tooltips: {
          callbacks: {
            title: function () {
              return "";
            },
            label: function (item) {
              return ` ${item.dataset.label}: ${item.formattedValue}`;
            }
          },
          displayColors: false,
        },
        hover: {
          mode: 'nearest',
          intersect: true
        },
        scales: {
          x: {
            display: true,
            adapters: {
              date: {
                locale: ru
              }
            },
            type: 'time',
            time: {
              unit: 'month'
            },
            offset: true
          },
          y: {
            display: true,
            scaleLabel: {
              display: true,
              labelString: 'Сумма'
            },
            suggestedMin: 0,
            beginAtZero: true,
          }
        }
      }
    };
    new Chart(ctx, config)
  },

  createTransactionsChart() {
    const ctx = document.getElementById('data-transactions');
    const colors = this.colors();

    var config = {
      type: 'line',
      data: {
        datasets: [
          {
            fill: false,
            borderColor: colors[0],
            backgroundColor: colors[0],
            data: this.transactions().map((u) => {
              return {
                x: u.date,
                y: u.transactions_count,
              }
            }),
          },
        ]
      },
      options: {
        title: {
          display: true,
          text: "Количество транзакции."
        },
        legend: {
          display: false
        },
        responsive: true,
        maintainAspectRatio: false,
        tooltips: {
          callbacks: {
            title: function () {
              return "";
            },
            label: function (item) {
              return ` ${item.formattedValue}`;
            }
          },
          displayColors: false,
        },
        hover: {
          mode: 'nearest',
          intersect: true
        },
        scales: {
          x: {
            display: true,
            adapters: {
              date: {
                locale: ru
              }
            },
            type: 'time',
            time: {
              unit: 'month'
            },
            offset: true
          },
          y: {
            display: true,
            scaleLabel: {
              display: true,
              labelString: 'Количество'
            },
            suggestedMin: 0,
            beginAtZero: true,
          }
        }
      }
    };
    new Chart(ctx, config)
  },


  createPopularCategoriesChart() {
    const ctx = document.getElementById('data-popular-categories');

    const data = this.popularCategories()
    let colors = this.colors()
    const datasets = Object.entries(data).flatMap(([category, groups], index) => {
      let color = colors[index % colors.length]

      return groups.flatMap((group) => {
        return {
          fill: false,
          pointRadius: 4,
          label: category,
          backgroundColor: color,
          borderColor: color,
          data: group.map((point) => {
            return {
              x: point.date,
              y: point.records_count,
              description: point.category_name
            }
          }),
        }
      })
    })

    var config = {
      type: 'line',
      data: {
        datasets: datasets
      },
      options: {
        title: {
          display: true,
          text: "Категории с наибольшим количеством транзакций."
        },
        legend: {
          display: true,
          labels: {
            filter: (current, data) => {
              return current.datasetIndex == data.datasets.findIndex((item) => item.label === current.text)
            },
          },
        },
        responsive: true,
        maintainAspectRatio: false,
        tooltips: {
          callbacks: {
            title: function (item) {
              return "";
            },
            label: function (item) {
              return `${item.dataset.label}: ${item.formattedValue}`;
            }
          },
          displayColors: false,
        },
        hover: {
          mode: 'nearest',
          intersect: true
        },
        scales: {
          x: {
            display: true,
            adapters: {
              date: {
                locale: ru
              }
            },
            type: 'time',
            time: {
              unit: 'month'
            },
            offset: true
          },
          y: {
            display: true,
            scaleLabel: {
              display: true,
              labelString: 'Количество транзакций'
            },
            suggestedMin: 0,
            beginAtZero: true,
          }
        }
      }
    };
    new Chart(ctx, config)
  },

  createMostExpensiveCategoriesChart() {
    const ctx = document.getElementById('data-most-expensive-categories');

    const data = this.mostExpensiveCategories()
    let colors = this.colors()
    const datasets = Object.entries(data).flatMap(([category, groups], index) => {
      let color = colors[index % colors.length]

      return groups.flatMap((group) => {
        return {
          fill: false,
          label: category,
          backgroundColor: color,
          borderColor: color,
          pointRadius: 4,
          data: group.map((point) => {
            return {
              x: point.date,
              y: point.sum_amount,
              description: point.category_name
            }
          }),
        }
      })
    })

    var config = {
      type: 'line',
      data: {
        datasets: datasets
      },
      options: {
        title: {
          display: true,
          text: "Категории с наибольшими расходами (BYN)."
        },
        legend: {
          display: true,
          labels: {
            filter: (current, data) => {
              return current.datasetIndex == data.datasets.findIndex((item) => item.label === current.text)
            },
          },
        },
        responsive: true,
        maintainAspectRatio: false,
        tooltips: {
          callbacks: {
            title: function (item) {
              return "";
            },
            label: function (item) {
              return `${item.dataset.label}: ${item.formattedValue}`;
            }
          },
          displayColors: false,
        },
        hover: {
          mode: 'nearest',
          intersect: true
        },
        scales: {
          x: {
            display: true,
            adapters: {
              date: {
                locale: ru
              }
            },
            type: 'time',
            time: {
              unit: 'month'
            },
            offset: true
          },
          y: {
            display: true,
            scaleLabel: {
              display: true,
              labelString: 'Сумма транзакций'
            },
            suggestedMin: 0,
            beginAtZero: true,
          }
        }
      }
    };
    new Chart(ctx, config)
  },

  createProfitsTrendChart() {
    const ctx = document.getElementById('data-profits-trend');

    var config = {
      type: 'line',
      data: {
        datasets: [
          {
            fill: false,
            label: 'Ежемесячная прибыль.',
            borderColor: "rgb(153, 102, 255)",
            data: this.profits().map((p) => {
              return {
                x: p.date,
                y: p.amount,
                description: p.description
              }
            }),
          },
        ]
      },
      options: {
        title: {
          display: true,
          text: "Ежемесячная прибыль."
        },
        legend: {
          display: false
        },
        responsive: true,
        maintainAspectRatio: false,
        tooltips: {
          callbacks: {
            title: function () {
              return "";
            },
            label: function (item) {
              return ` ${item.formattedValue} $`;
            }
          },
          displayColors: false,
        },
        hover: {
          mode: 'nearest',
          intersect: true
        },
        scales: {
          x: {
            display: true,
            adapters: {
              date: {
                locale: ru
              }
            },
            type: 'time',
            time: {
              unit: 'month'
            },
            offset: true
          },
          y: {
            display: true,
            scaleLabel: {
              display: true,
              labelString: 'Сумма'
            },
            suggestedMin: -100,
            suggestedMax: 100,
            beginAtZero: true,
          }
        }
      }
    };
    new Chart(ctx, config)
  },

  mounted() {
    this.createUsersChart()
    this.createTransactionsChart()
    this.createPopularCategoriesChart()
    this.createMostExpensiveCategoriesChart()
    this.createProfitsTrendChart()
  }
}
