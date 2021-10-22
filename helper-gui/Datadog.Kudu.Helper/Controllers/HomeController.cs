using Datadog.Kudu.Helper.Models;
using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace Datadog.Kudu.Helper.Controllers
{
	public class HomeController : Controller
	{
		private static HttpClient StaticClient = new HttpClient();
		private HttpClient _httpClient;

		public HomeController()
		{
			_httpClient = StaticClient;
		}

		public HomeController(HttpClient httpClient)
		{
			_httpClient = httpClient ?? new HttpClient();
		}

		[HttpGet]
		public ActionResult Index()
		{
			var model = new DatadogConfigurationModel
			{
				Env = Environment.GetEnvironmentVariable("DD_ENV"),
				Service = Environment.GetEnvironmentVariable("DD_SERVICE"),
				Version = Environment.GetEnvironmentVariable("DD_VERSION"),
				Site = Environment.GetEnvironmentVariable("DD_SITE"),
				ApiKey = Environment.GetEnvironmentVariable("DD_API_KEY"),
			};

			return View(model);
		}

		[HttpPost]
		public ActionResult Index(DatadogConfigurationModel model)
		{
			// TODO: Allow modification

			return RedirectToAction("Index");
		}

		[HttpGet]
		public ActionResult Troubleshooting()
		{
			var model = new DatadogTroubleshootingModel();
			return View(model);
		}

		[HttpGet]
		public string Cookies()
		{
			try
			{
				return BuildCookiePassthrough();
			}
			catch (Exception ex)
			{
				return ex.ToString();
			}
		}

		private string BuildCookiePassthrough()
		{
			var allCookies = "";
			var cookieKeys = Request.Cookies.AllKeys;
			foreach (var key in cookieKeys)
			{
				var cookie = Request.Cookies[key];
				allCookies += $"{key}={string.Join(" | ", cookie.Values)}; ";
			}
			return allCookies;
		}

		[HttpGet]
		public async Task<string> WebAppDiagnostics()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var processInfoUrl = $"{baseUri}/api/processes/-1";
				HttpResponseMessage result = await SendRequest(processInfoUrl);
				var webProcessInfo = await result.Content.ReadAsStringAsync();
				//var webProcessInfo = "fake_json";

				return webProcessInfo;
			}
			catch (Exception ex)
			{
				return $"{ex.ToString()}" + Environment.NewLine + Environment.NewLine + "";
			}
		}

		private async Task<HttpResponseMessage> SendRequest(string processInfoUrl)
		{
			var message = new HttpRequestMessage(HttpMethod.Get, processInfoUrl);
			// message.Headers.Add("Cookie", BuildCookiePassthrough());
			CopyTo(Request, message);
			var result = await _httpClient.SendAsync(message);
			result.EnsureSuccessStatusCode();
			return result;
		}

		/// <summary>
		/// Copies all headers and content (except the URL) from an incoming to an outgoing
		/// request.
		/// </summary>
		/// <param name="source">The request to copy from</param>
		/// <param name="destination">The request to copy to</param>
		public static void CopyTo(HttpRequestBase source, HttpRequestMessage destination)
		{
			// destination.Method = source.HttpMethod;

			// Copy unrestricted headers (including cookies, if any)
			foreach (var headerKey in source.Headers.AllKeys)
			{
				switch (headerKey)
				{
					case "Connection":
					case "Content-Length":
					case "Date":
					case "Expect":
					case "Host":
					case "If-Modified-Since":
					case "Range":
					case "Transfer-Encoding":
					case "Proxy-Connection":
						// Let IIS handle these
						break;

					//case "Accept":
					//case "Content-Type":
					//case "Referer":
					//case "User-Agent":
					//	// Restricted - copied below
					//	break;

					default:
						destination.Headers.Add(headerKey, source.Headers[headerKey]);
						break;
				}
			}

			//// Copy restricted headers
			//if (source.AcceptTypes.Any())
			//{
			//	destination.Accept = string.Join(",", source.AcceptTypes);
			//}
			//destination.ContentType = source.ContentType;
			//destination.Referer = source.UrlReferrer.AbsoluteUri;
			//destination.UserAgent = source.UserAgent;

			//// Copy content (if content body is allowed)
			//if (source.HttpMethod != "GET"
			//	&& source.HttpMethod != "HEAD"
			//	&& source.ContentLength > 0)
			//{
			//	var destinationStream = destination.GetRequestStream();
			//	source.InputStream.CopyTo(destinationStream);
			//	destinationStream.Close();
			//}
		}

		[HttpGet]
		public async Task<byte[]> GetDatadogLogs()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var datadogLogZipUrl = $"{baseUri}/api/zip/LogFiles/datadog";
				var datadogLogBytes = await _httpClient.GetByteArrayAsync(datadogLogZipUrl);

				return datadogLogBytes;
			}
			catch (Exception ex)
			{
				return new byte[0];
			}
		}

		[HttpGet]
		public async Task<byte[]> GetEventLog()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var eventLogUrl = $"{baseUri}/api/vfs/LogFiles/eventlog.xml";
				var fileBytes = await _httpClient.GetByteArrayAsync(eventLogUrl);

				return fileBytes;
			}
			catch (Exception ex)
			{
				return new byte[0];
			}
		}

		private string GetBaseUrl()
		{
			var currentUrl = Request.Url;
			var baseUri = currentUrl.GetLeftPart(UriPartial.Authority);
			return baseUri;
		}

		[HttpGet]
		public async Task<FileResult> Diagnostics()
		{
			var currentUrl = Request.Url;
			var baseUri = currentUrl.GetLeftPart(UriPartial.Authority);

			var webProcessInfo = await WebAppDiagnostics();

			var datadogLogBytes = await GetDatadogLogs();

			var eventLogBytes = await GetEventLog();

			var dumpName = $"datadog_diagnostics_{DateTime.UtcNow.ToString("yyyy-dd-M--HH-mm-ss")}";
			var directory = ControllerContext.HttpContext.Server.MapPath($"~/{dumpName}");
			Directory.CreateDirectory(directory);

			System.IO.File.WriteAllText(Path.Combine(directory, "web-process.json"), webProcessInfo);
			System.IO.File.WriteAllBytes(Path.Combine(directory, "datadog.zip"), datadogLogBytes);
			System.IO.File.WriteAllBytes(Path.Combine(directory, "eventlog.xml"), eventLogBytes);

			var archive = $"{directory}.zip";
			System.IO.Compression.ZipFile.CreateFromDirectory(directory, $"{dumpName}.zip");

			var allBytes = System.IO.File.ReadAllBytes(archive);

			DeleteDirectory(directory);
			System.IO.File.Delete(archive);

			return File(allBytes, "application/zip", archive);
		}

		/// <summary>
		/// Depth-first recursive delete, with handling for descendant 
		/// directories open in Windows Explorer.
		/// </summary>
		public static void DeleteDirectory(string path)
		{
			foreach (string directory in Directory.GetDirectories(path))
			{
				DeleteDirectory(directory);
			}

			try
			{
				Directory.Delete(path, true);
			}
			catch (IOException)
			{
				Directory.Delete(path, true);
			}
			catch (UnauthorizedAccessException)
			{
				Directory.Delete(path, true);
			}
		}
	}
}