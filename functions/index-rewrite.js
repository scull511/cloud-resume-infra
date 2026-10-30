function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // URI ends with a slash -> append index.html
  if (uri.endsWith('/')) {
    request.uri += 'index.html';
  }
  // If URI has no trailing slash and does not contain a file extension (e.g. .html or .png) -> append /index.html
  else if (!uri.includes('.')) {
    request.uri += '/index.html';
  }

  return request;
}
