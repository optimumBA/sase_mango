let CalculatorInputHooks = {}

CalculatorInputHooks.FieldReset = {
    mounted() {

        let flipElement = this.el
        let inputElement = document.getElementById('select-field')

        flipElement.addEventListener('click', (e) => {
            this.pushEvent('toggle_issuer_input_cover', {})
            inputElement.focus()
            inputElement.value = ''
        })
    }
}

CalculatorInputHooks.InputField = {
    mounted() {
        const hook = this
        const inputElement = hook.el

        inputElement.addEventListener('keyup', (event) => {
            if (event.code == 'ArrowUp' || event.code == 'ArrowDown') {
                hook.pushEventTo('#issuer-select-comp', 'scroll_list', { key: event.code })
            } else if (event.code != 'Tab' && event.code != 'Enter') {
                hook.pushEventTo('#issuer-select-comp', 'select_input_changed', { key: event.code, value: event.target.value })
            }
        })

        inputElement.addEventListener('keydown', (event) => {
            if (event.code == 'Tab' || event.code == 'Enter') {
                inputElement.blur()
                hook.pushEventTo('#issuer-select-comp', 'select_input_changed', { key: event.code, value: event.target.value })
            }
        })
    }
}

export default CalculatorInputHooks
