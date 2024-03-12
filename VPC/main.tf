resource "google_compute_network" "gcp_vpc_network" {
  name = "gcp-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
}