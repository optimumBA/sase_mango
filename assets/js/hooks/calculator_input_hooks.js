let CalculatorInputHooks = {}

CalculatorInputHooks.FieldReset = {
    mounted() {

        let flipElement = this.el
        let inputElement = document.getElementById('select-field')

        flipElement.addEventListener('click', (e) => {

            this.pushEvent('flip_input', {})

            inputElement.focus()
            inputElement.value = ""

        })
    }
}

export default CalculatorInputHooks
