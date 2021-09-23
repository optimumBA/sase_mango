let SecuritiesHooks = {}

const soundSrcs = [
  'audio/bell.wav',
  'audio/cat_meow.wav',
  'audio/cat_meow2.wav',
  'audio/tiger_growl.wav',
]

SecuritiesHooks.SecuritiesList = {
  mounted() {
    let hook = this

    this.requestNotificationPermission(() => {
      hook.handleEvent('send_notification', ({ body }) => {
        let randomIndex = Math.floor(Math.random() * soundSrcs.length)
        let soundSrc = soundSrcs[randomIndex]
        let notificationSound = new Audio(soundSrc)
        notificationSound.play()

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
