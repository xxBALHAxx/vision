const downloadButtons = document.querySelectorAll('[href="apk/vision-quest.apk"]');

downloadButtons.forEach((downloadButton) => {
  downloadButton.addEventListener('click', () => {
    downloadButton.setAttribute('aria-label', 'Downloading Vision Quest APK');
  });
});
