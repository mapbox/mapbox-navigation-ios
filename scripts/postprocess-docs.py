import json, os, re, fileinput, getopt, sys, urllib.request

base_url=''
docs_root=''

try:
  opts, args = getopt.getopt(sys.argv[1:], "b:d:")
except getopt.GetoptError:
  print('post-document.py -b <base_url> -d <docs_root>')
  sys.exit(2)
for opt, arg in opts:
  if opt in ("-b", "--baseurl"):
     base_url = arg
  elif opt in ("-d", "--docsroot"):
     docs_root = arg
     
# receive, parse and remove index file
with urllib.request.urlopen('{base_url}/search.json'.format(base_url=base_url)) as url:
  index_data = json.load(url)

# fill the [symbol: url] dictionary
symbols = dict()

for path in filter(lambda p: (p.startswith('Classes') or p.startswith('Structs') or p.startswith('Enums')) and p.endswith('.html'), index_data):
  # path is expected to be in the format Classes/VisualInstruction/Component/ImageRepresentation/Format.html
  # VisualInstruction.Component.ImageRepresentation.Format -> https://example.com/Classes/VisualInstruction/Component/ImageRepresentation/Format.html
  symbols[".".join(path.split('.')[0].split('/')[1:])] = '{base}/{path}'.format(base=base_url, path=path)
  
# substitute symbols in all html files with links
for root, dirs, files in os.walk(docs_root):
  for file in [f for f in files if f.endswith('.html')]:
    file_path = os.path.join(root, file)
    
    for line in fileinput.FileInput(file_path, inplace=True):
      line = re.sub(r"<span class=\"kt\">({keys})</span>".format(keys='|'.join(symbols.keys())), lambda x: '<span class=\"kt\"><a href=\"{link}\">{symbol}</a></span>'.format(link=symbols.get(x.group(1)), symbol=x.group(1)), line.rstrip('\n'))
      line = re.sub(r"<code>({keys})</code>".format(keys='|'.join(symbols.keys())), lambda x: '<code><a href=\"{link}\">{symbol}</a></code>'.format(link=symbols.get(x.group(1)), symbol=x.group(1)), line.rstrip('\n'))
      
      # Mapbox Navigation specific
      line = re.sub(r'MapboxNavigation\s+(Docs|Reference)', lambda x: 'Mapbox Navigation SDK for iOS {section}'.format(section=x.group(1)), line.rstrip('\n'))
      
      sys.stdout.write(line + "\n")
