using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace Datadog.Kudu.Manager
{
	[Route("api/[controller]")]
	[ApiController]
	public class DiagnosticsController : ControllerBase
	{
		private static HashSet<string> HeadersToForward = new HashSet<string>()
		{
			"Accept",
			"Accept-Encoding",
			"Accept-Language",
			"Cache-Control",
			"Connection",
			"Cookie",
			"ARRAffinity",
			"ARRAffinitySameSite",
			"Host",
			"Max-Forwards",
			"Pragma",
			"User-Agent",
			"sec-ch-ua=",
			"sec-ch-ua-mobile",
			"sec-ch-ua-platform",
			"Upgrade-Insecure-Requests",
			"Sec-Fetch-Site",
			"Sec-Fetch-Mode",
			"Sec-Fetch-User",
			"Sec-Fetch-Dest",
			//"X-WAWS-Unencoded-URL",
			"CLIENT-IP",
			//"X-ARR-LOG-ID",
			"DISGUISED-HOST",
			"X-SITE-DEPLOYMENT-ID",
			"WAS-DEFAULT-HOSTNAME",
			//"X-Original-URL",
			"X-MS-CLIENT-PRINCIPAL-NAME",
			"X-MS-CLIENT-DISPLAY-NAME",
			"X-Forwarded-For",
			"X-ARR-SSL",
			"X-Forwarded-Proto",
			"X-AppService-Proto",
			"X-Forwarded-TlsVersion",
		};
		private readonly IHttpClientFactory _clientFactory;
		private readonly IWebHostEnvironment _hostEnvironment;

		public DiagnosticsController(IHttpClientFactory clientFactory, IWebHostEnvironment environment)
		{
			_clientFactory = clientFactory;
			_hostEnvironment = environment;
		}

		[HttpGet("cookies", Name = "Cookies")]
		public string Cookies()
		{
			try
			{
				return string.Join("; ", Request.Cookies.Select(c => $"{c.Key}={c.Value}"));
				//return BuildCookiePassthrough();
			}
			catch (Exception ex)
			{
				return ex.ToString();
			}
		}

		[HttpGet("headers", Name = "Headers")]
		public string Headers()
		{
			try
			{
				var headers = Request.Headers;
				var response = "";
				foreach (var header in headers)
				{
					response += $"{header.Key}={header.Value}";
					response += Environment.NewLine;
				}

				return response;
			}
			catch (Exception ex)
			{
				return ex.ToString();
			}
		}

		[HttpGet("server-variables", Name = "IISVariables")]
		public string IISVariables()
		{
			try
			{

				var serverVariables = HttpContext.Features.Get<IServerVariablesFeature>();

				foreach (var key in ServerVariables.Keys)
				{
					var value = serverVariables[key];
					if (ServerVariables.Variables.ContainsKey(key))
					{
						ServerVariables.Variables[key] = value;
					}
					else
					{
						ServerVariables.Variables.Add(key, value);
					}
				}

				var response = "";
				foreach (var header in ServerVariables.Variables)
				{
					response += $"{header.Key}={header.Value}";
					response += Environment.NewLine;
				}

				return response;
			}
			catch (Exception ex)
			{
				return ex.ToString();
			}
		}

		[HttpGet("verify-forwarding", Name = "VerifyHeaderForwarding")]
		public async Task<string> VerifyHeaderForwarding()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var url = $"{baseUri}/Datadog/api/diagnostics/headers";
				if (baseUri.Contains("localhost"))
				{
					url = $"{baseUri}/api/diagnostics/headers";
				}
				HttpResponseMessage result = await SendRequest(url);
				var info = await result.Content.ReadAsStringAsync();
				return info;
			}
			catch (Exception ex)
			{
				return ex.ToString();
			}
		}

		[HttpGet("forward-header", Name = "ForwardHeader")]
		public async Task<string> ForwardHeader()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var url = $"{baseUri}/Datadog/api/diagnostics/verify-forwarding";
				if (baseUri.Contains("localhost"))
				{
					url = $"{baseUri}/api/diagnostics/verify-forwarding";
				}
				var message = new HttpRequestMessage(HttpMethod.Get, url);
				message.Headers.Add("DISGUISED-HOST", "PLEASE-WORK-x64.scm.azurewebsites.net");
				//var headers = Request.Headers;

				// message.Headers.Add("Cookie", BuildCookiePassthrough());
				//foreach (var headerGroup in headers.GroupBy(h => h.Key))
				//{
				//	var key = headerGroup.Key;
				//	if (key != "Cookie")
				//	{
				//		continue;
				//	}
				//	var headerValues = headerGroup.Select(hg => (string)hg.Value);
				//	message.Headers.TryAddWithoutValidation(key, headerValues);
				//}

				//CopyTo(Request, message);

				var client = _clientFactory.CreateClient();
				var result = await client.SendAsync(message);
				result.EnsureSuccessStatusCode();
				var info = await result.Content.ReadAsStringAsync();
				return info;
			}
			catch (Exception ex)
			{
				return ex.ToString();
			}
		}

		[HttpGet("webapp", Name = "WebAppDiagnostics")]
		public async Task<string> WebAppDiagnostics()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var url = $"{baseUri}/api/processes/-1";
				HttpResponseMessage result = await SendRequest(url);
				var webProcessInfo = await result.Content.ReadAsStringAsync();
				//var webProcessInfo = "fake_json";

				return webProcessInfo;
			}
			catch (Exception ex)
			{
				return $"{ex.ToString()}" + Environment.NewLine + Environment.NewLine + "";
			}
		}

		[HttpGet("datadoglogs", Name = "GetDatadogLogs")]
		public async Task<byte[]> GetDatadogLogs()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var url = $"{baseUri}/api/zip/LogFiles/datadog";
				HttpResponseMessage result = await SendRequest(url);
				return await result.Content.ReadAsByteArrayAsync();
			}
			catch (Exception ex)
			{
				return new byte[0];
			}
		}

		[HttpGet("eventlog", Name = "GetEventLog")]
		public async Task<byte[]> GetEventLog()
		{
			try
			{
				string baseUri = GetBaseUrl();
				var url = $"{baseUri}/api/vfs/LogFiles/eventlog.xml";
				HttpResponseMessage result = await SendRequest(url);
				return await result.Content.ReadAsByteArrayAsync();
			}
			catch (Exception ex)
			{
				return new byte[0];
			}
		}

		private string GetBaseUrl()
		{
			var currentUrl = Microsoft.AspNetCore.Http.Extensions.UriHelper.GetDisplayUrl(Request);
			var currentUri = new Uri(currentUrl);
			var baseUri = currentUri.GetLeftPart(UriPartial.Authority);
			return baseUri;
		}

		[HttpGet]
		public async Task<FileResult> Diagnostics()
		{
			var webProcessInfo = await WebAppDiagnostics();

			var datadogLogBytes = await GetDatadogLogs();

			var eventLogBytes = await GetEventLog();

			var dumpName = $"datadog_diagnostics_{DateTime.UtcNow.ToString("yyyy-dd-M--HH-mm-ss")}";
			var directory = Path.Combine(_hostEnvironment.WebRootPath, $"{dumpName}");
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


		private async Task<HttpResponseMessage> SendRequest(string processInfoUrl)
		{
			var message = new HttpRequestMessage(HttpMethod.Get, processInfoUrl);
			var headers = Request.Headers;

			//"X-WAWS-Unencoded-URL",
			//"X-ARR-LOG-ID",
			//"X-Original-URL",
			var relative = new Uri(processInfoUrl);
			message.Headers.TryAddWithoutValidation("X-WAWS-Unencoded-URL", relative.PathAndQuery);
			message.Headers.TryAddWithoutValidation("X-Original-URL", relative.PathAndQuery);
			message.Headers.TryAddWithoutValidation("X-ARR-LOG-ID", Guid.NewGuid().ToString());

			foreach (var headerGroup in headers.GroupBy(h => h.Key))
			{
				var key = headerGroup.Key;
				if (HeadersToForward.Contains(key))
				{
					var headerValues = headerGroup.Select(hg => (string)hg.Value);
					message.Headers.TryAddWithoutValidation(key, headerValues);
				}
			}

			//CopyTo(Request, message);

			var client = _clientFactory.CreateClient();
			var result = await client.SendAsync(message);
			//result.EnsureSuccessStatusCode();
			return result;

			//var client = HttpClientHelper.CreateClient(GetBaseUrl(), null, null);
			//var result = await client.SendAsync(message);
			//result.EnsureSuccessStatusCode();
			//return result;
		}

		/// <summary>
		/// Depth-first recursive delete, with handling for descendant 
		/// directories open in Windows Explorer.
		/// </summary>
		private static void DeleteDirectory(string path)
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

		private string BuildCookiePassthrough()
		{
			var headers = Request.Headers;

			// message.Headers.Add("Cookie", BuildCookiePassthrough());
			foreach (var headerGroup in headers.GroupBy(h => h.Key))
			{
				var key = headerGroup.Key;
				if (key != "Cookie")
				{
					continue;
				}
				var headerValues = headerGroup.Select(hg => (string)hg.Value);
				return string.Join(";", headerValues);
			}

			var allCookies = "";
			foreach (var cookie in Request.Cookies)
			{
				allCookies += $"{cookie.Key}={string.Join(" | ", cookie.Value)}; ";
			}
			return allCookies;
		}
	}
}
