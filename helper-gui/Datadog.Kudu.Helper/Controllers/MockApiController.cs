using Datadog.Kudu.Helper.Models;
using System;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Mvc;

namespace Datadog.Kudu.Helper.Controllers
{
	public class MockApiController : Controller
	{
		//var processInfoUrl = $"{baseUri}/api/processes/-1";
		//var datadogLogZipUrl = $"{baseUri}/api/zip/LogFiles/datadog";
		//var eventLogUrl = $"{baseUri}/api/vfs/LogFiles/eventlog.xml";

		[HttpGet]
		public string Processes(int id)
		{
			return "{ FakeJson: true }";
		}

		[HttpGet]
		public byte[] ZippedLogFiles(string directory)
		{
			return System.IO.File.ReadAllBytes(directory);
		}

		[HttpGet]
		public byte[] VfsLogFiles(string file)
		{
			return System.IO.File.ReadAllBytes(file);
		}
	}
}