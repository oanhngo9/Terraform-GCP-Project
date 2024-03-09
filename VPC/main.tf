resource "google_compute_network" "vpc_network" {
  name = "oanh-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
}