resource "google_compute_network" "gcp_vpc_network" {
  name = "dec-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
}

output "vpc_self_link" {
  value = google_compute_network.gcp_vpc_network.self_link
}