define(['jquery', 'TYPO3/CMS/Backend/Notification'], function ($, Notification) {
  $('.event-filter').on('change', function () {
    Notification.info('Filter', 'changed');
  });
});
