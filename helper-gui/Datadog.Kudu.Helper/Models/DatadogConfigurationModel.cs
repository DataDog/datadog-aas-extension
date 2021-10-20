namespace Datadog.Kudu.Helper.Models
{
	public class DatadogConfigurationModel
	{
		public string Env { get; set; }
		public string Service { get; set; }
		public string Version { get; set; }
		public string ApiKey { get; set; }
		public string Site { get; set; }
	}
}