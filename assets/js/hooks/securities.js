let SecuritiesHooks = {}

SecuritiesHooks.SecuritiesList = {
  mounted() {
    let hook = this

    this.requestNotificationPermission(() => {
      hook.handleEvent('send_notification', ({ body }) => {
        new Notification('SaseMango', { body: body })
      })
    })
  },

  requestNotificationPermission(callback) {
    if (!('Notification' in window)) {
      // Browser does not support desktop notifications
    } else if (Notification.permission === 'granted') {
      callback()
    } else if (Notification.permission !== 'denied') {
      Notification.requestPermission((permission) => {
        if (permission == 'granted') {
          callback()
        }
      })
    }
  },
}

export default SecuritiesHooks
