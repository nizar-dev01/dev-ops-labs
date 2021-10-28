output "server-1-id" {
  value = aws_instance.application-server-1.id
}
output "server-2-id" {
  value = aws_instance.application-server-2.id
}
output "load-balancer-dns" {
  value = aws_lb.load-balancer.dns_name
}
