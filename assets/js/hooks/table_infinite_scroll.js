export default {
  mounted() {
    this.pageNumber = this.getPage()
    this.observer = new IntersectionObserver(
      (entries) => {
        const target = entries[0]
        if (target.isIntersecting && this.pageNumber == this.getPage()) {
          this.pageNumber = parseInt(this.pageNumber) + 1
          this.pushEvent('load_more', {})
        }
      },
      {
        root: null,
        rootMargin: '0px',
        threshold: 1.0,
      }
    )
    this.observer.observe(this.el)
  },
  beforeDestroy() {
    this.observer.unobserve(this.el)
  },
  updated() {
    this.pageNumber = this.getPage()
  },
  getPage() {
    return this.el.dataset.pageNumber
  },
}
