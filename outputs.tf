output "proxy_ip" {
  value = aws_eip.proxy.public_ip
}