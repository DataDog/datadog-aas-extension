using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Datadog.Kudu.Manager.Pages
{
	public class IndexModel : PageModel
	{
		private readonly ILogger<IndexModel> _logger;

		public string ApiKey { get; set; }
		public string Env { get; set; }
		public string Service { get; set; }
		public string Version { get; set; }
		public string Site { get; set; }

		public IndexModel(ILogger<IndexModel> logger)
		{
			_logger = logger;
		}

		public void OnGet()
		{
			ApiKey = Environment.GetEnvironmentVariable("DD_API_KEY");
			Env = Environment.GetEnvironmentVariable("DD_ENV");
			Service = Environment.GetEnvironmentVariable("DD_SERVICE");
			Version = Environment.GetEnvironmentVariable("DD_VERSION");
			Site = Environment.GetEnvironmentVariable("DD_SITE");
		}
	}
}
