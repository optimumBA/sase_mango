let CalculatorInputHooks = {}

CalculatorInputHooks.FieldReset = {
    mounted() {

        let flip_el = this.el
        let input_el = document.getElementById("select-field")

        flip_el.addEventListener('click', (e) => {

            this.pushEvent("input_flip", {});

            input_el.focus()
            input_el.value = "";

        })
    }
}

export default CalculatorInputHooks;