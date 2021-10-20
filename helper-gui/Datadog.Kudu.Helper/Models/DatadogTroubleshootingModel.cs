using System.Collections.Generic;

namespace Datadog.Kudu.Helper.Models
{
	public class DatadogTroubleshootingModel
	{
		public List<string> Problems { get; set; } = new List<string>();
	}
}