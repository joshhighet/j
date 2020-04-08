import re
import requests

def parse_args():
	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument('-d', '--domain', type=str, required=True, help="domain to search transparency events for")
	return parser.parse_args()

def banner():
	global version

def clear_url(target):
	return re.sub('.*www\.','',target,1).split('/')[0].strip()

def main():
	banner()
	args = parse_args()

	subdomains = []
	target = clear_url(args.domain)

	req = requests.get("https://crt.sh/?q=%.{d}&output=json".format(d=target))

	for (key,value) in enumerate(req.json()):
		subdomains.append(value['name_value'])

	subdomains = sorted(set(subdomains))

	for subdomain in subdomains:
		print("[-]  {s}".format(s=subdomain))
main()
