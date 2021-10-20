using Datadog.Kudu.Helper.Models;
using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
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
		public async Task<FileResult> Diagnostics()
		{
			var currentUrl = Request.Url;
			var baseUri = currentUrl.GetLeftPart(UriPartial.Authority);

			var processInfoUrl = $"{baseUri}/api/processes/-1";
			var webProcessInfo = await _httpClient.GetStringAsync(processInfoUrl);
			//var webProcessInfo = "fake_json";

			var datadogLogZipUrl = $"{baseUri}/api/zip/LogFiles/datadog";
			var datadogLogBytes = await _httpClient.GetByteArrayAsync(datadogLogZipUrl);
			//var datadogLogBytes = new byte[] { 1, 1, 1, 1 };

			var eventLogUrl = $"{baseUri}/api/vfs/LogFiles/eventlog.xml";
			var eventLogBytes = await _httpClient.GetByteArrayAsync(eventLogUrl);
			//var eventLogBytes = new byte[] { 1, 1, 1, 1 };

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