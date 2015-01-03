ExternDisk
==========

####Overview####
The project is intended to provide curious users a platform to share resources from their local computers to remote hosts. Each users specifies the files that are visible/available to the other hosts. The available files are downloaded through File transfer protocol (the inbuilt Net::FTP Class is not used). The remote hosts to which a particular user is connected is shown to latter as a available peers list. Each users can browse through the file structure of others after being permitted by the owner. The entire authentication, browsing, searching and file transferring is done through Socket Programming. Each Peer has a Server and Client of its own. When the peer wants to browse a remote peer’s disk, it gets connected to the latter’s server and vice-versa.

Find the concise report [here](https://drive.google.com/file/d/0B2n81PJ3ea5ba2xKU3F3ZHU5N2M/view?usp=sharing)

####Specifications####
* Programming Language : [Ruby](https://www.ruby-lang.org/en/)
* GUI Library : [Shoes](http://shoesrb.com/)
* Only for Local Area Networks like Hostels, offices, etc.
* Only for Linux Users

####Getting Started####
1. Git Clone this repo.
2. Install Ruby
3. [Download and install Shoes](http://shoesrb.com/downloads/).
4. Install nmap(this helps in getting the list of all hosts on the same network).
For Ubuntu:
`sudo apt-get install nmap`
5. Open Shoes and run server.rb script.

Any errors will appear in Shoes console.

####Contribution####
Want to contribute to the still-naive project? First go throught the Getting Started section and start coding! Submit pull requests and I'll be happy to merge them.
