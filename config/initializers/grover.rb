Grover.configure do |config|
  config.options = {
    format: "A4",
    margin: {
      top: "10mm",
      bottom: "10mm",
      left: "10mm",
      right: "10mm"
    },
    print_background: true,
    prefer_css_page_size: true,
    emulate_media: "print",
    timeout: 60_000,
    launch_args: %w[--no-sandbox --disable-setuid-sandbox]
  }
end
