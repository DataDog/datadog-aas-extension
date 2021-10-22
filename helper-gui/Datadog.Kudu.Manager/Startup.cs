using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Datadog.Kudu.Manager
{
	public class Startup
	{
		public Startup(IConfiguration configuration)
		{
			Configuration = configuration;
		}

		public IConfiguration Configuration { get; }

		// This method gets called by the runtime. Use this method to add services to the container.
		public void ConfigureServices(IServiceCollection services)
		{
			services.AddRazorPages();
			services.AddHttpClient();
			//services.AddHeaderPropagation(options =>
			//{
			//	// Add SCM headers if present
			//	//options.Headers.Add("Accept");
			//	//options.Headers.Add("Accept-Encoding");
			//	//options.Headers.Add("Accept-Language");
			//	//options.Headers.Add("Cache-Control");
			//	options.Headers.Add("Connection");
			//	options.Headers.Add("Cookie=");
			//	options.Headers.Add("ARRAffinity");
			//	options.Headers.Add("ARRAffinitySameSite");
			//	options.Headers.Add("Host");
			//	options.Headers.Add("Max-Forwards");
			//	options.Headers.Add("Pragma");
			//	options.Headers.Add("User-Agent");
			//	//options.Headers.Add("sec-ch-ua");
			//	//options.Headers.Add("sec-ch-ua-mobile");
			//	//options.Headers.Add("sec-ch-ua-platform");
			//	options.Headers.Add("Upgrade-Insecure-Requests");
			//	options.Headers.Add("Sec-Fetch-Site");
			//	options.Headers.Add("Sec-Fetch-Mode");
			//	options.Headers.Add("Sec-Fetch-User");
			//	options.Headers.Add("Sec-Fetch-Dest");
			//	//options.Headers.Add("X-WAWS-Unencoded-URL");
			//	options.Headers.Add("CLIENT-IP");
			//	//options.Headers.Add("X-ARR-LOG-ID");
			//	options.Headers.Add("DISGUISED-HOST");
			//	options.Headers.Add("X-SITE-DEPLOYMENT-ID");
			//	options.Headers.Add("WAS-DEFAULT-HOSTNAME");
			//	//options.Headers.Add("X-Original-URL");
			//	options.Headers.Add("X-MS-CLIENT-PRINCIPAL-NAME");
			//	options.Headers.Add("X-MS-CLIENT-DISPLAY-NAME");
			//	options.Headers.Add("X-Forwarded-For");
			//	options.Headers.Add("X-ARR-SSL");
			//	options.Headers.Add("X-Forwarded-Proto");
			//	options.Headers.Add("X-AppService-Proto");
			//	options.Headers.Add("X-Forwarded-TlsVersion");
			//});
		}

		// This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
		public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
		{
			if (env.IsDevelopment())
			{
				app.UseDeveloperExceptionPage();
			}
			else
			{
				app.UseExceptionHandler("/Error");
				// The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
				app.UseHsts();
			}

			app.UseHttpsRedirection();
			app.UseStaticFiles();

			app.UseRouting();

			app.UseAuthorization();

			app.UseEndpoints(endpoints =>
			{
				endpoints.MapRazorPages();
				endpoints.MapControllers();
			});

			app.UseCookiePolicy();
			app.UseAuthentication();

			//app.Use(async (context, next) =>
			//{
			//	var serverVariables = context.Features.Get<IServerVariablesFeature>();

			//	foreach (var key in ServerVariables.Keys)
			//	{
			//		var value = serverVariables[key];
			//		if (ServerVariables.Variables.ContainsKey(key))
			//		{
			//			ServerVariables.Variables[key] = value;
			//		}
			//		else
			//		{
			//			ServerVariables.Variables.Add(key, value);
			//		}
			//	}

			//	await next.Invoke();
			//});
		}
	}
}
