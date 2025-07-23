# Banking Portal Microservices Workshop Documentation

## Microservices Overview

| Service Name         | Language/Framework | Deployment Location           | Swagger URL/Endpoint                                        |
|---------------------|-------------------|------------------------------|-------------------------------------------------------------|
| login-ms            | Node.js (Express) | OCI Container Instance      | http://192.18.141.177/api-docs/                             |
| agendar-ms          | Python (Fn)       | Oracle Cloud Functions      | https://[region].apigateway.[region].oci.customer-oci.com/agenda/v1/* |
| cotizar-ms          | Python (FastAPI)  | OKE/Kubernetes             | http://portalbancario.alquinta.xyz/cotizar/swagger-ui/index.html |
| pagar-ms            | Java (Spring Boot)| OKE/Kubernetes             | http://portalbancario.alquinta.xyz/pagar/swagger-ui/index.html |
| movimientos-ms      | Python (FastAPI)  | OKE/Kubernetes             | http://portalbancario.alquinta.xyz/movimientos/swagger-ui/index.html |
| cc-movimientos-ms   | Python (FastAPI)  | OKE/Kubernetes             | http://portalbancario.alquinta.xyz/cc-movimientos/swagger-ui/index.html |

## Database Access Information (MySQL)

### MySQL Database Connection (Common for all services)
```bash
Host: 10.0.0.12
Port: 3306
Username: admin
Password: Welcome1.

# Connection commands for different services:

# For login-ms
mysql -h 10.0.0.12 -u admin -p 

Pass 'Welcome1.'


```

### Important Notes about Database Connection
1. All microservices connect to a single MySQL instance at 10.0.0.12
2. The common credentials are:
   - Username: admin
   - Password: Welcome1.
3. Each service uses its own database on the same instance
4. Make sure you're connected to the VPN or appropriate network to access the database
5. The database connection is secured within the private subnet

## Function Testing (agendar-ms)

### API Gateway Endpoint
```
https://[region].apigateway.[region].oci.customer-oci.com/agenda/v1/reservas
```

### Test JSON Samples

1. Create Reservation (POST /reservas)
```json
{
    "usuario_id": "12345",
    "fecha": "2024-02-20",
    "hora": "14:30",
    "tipo_servicio": "atencion_ejecutivo",
    "sucursal": "central"
}
```

2. Get User Reservations (GET /reservas/{usuario_id})
```
GET /reservas/12345
```

3. Delete Reservation (DELETE /reservas/{reserva_id})
```
DELETE /reservas/67890
```

### Testing via curl

1. Create Reservation:
```bash
curl -X POST \
  https://[region].apigateway.[region].oci.customer-oci.com/agenda/v1/reservas \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <jwt_token>' \
  -d '{
    "usuario_id": "12345",
    "fecha": "2024-02-20",
    "hora": "14:30",
    "tipo_servicio": "atencion_ejecutivo",
    "sucursal": "central"
}'
```

2. Get User Reservations:
```bash
curl -X GET \
  https://[region].apigateway.[region].oci.customer-oci.com/agenda/v1/reservas/12345 \
  -H 'Authorization: Bearer <jwt_token>'
```

3. Delete Reservation:
```bash
curl -X DELETE \
  https://[region].apigateway.[region].oci.customer-oci.com/agenda/v1/reservas/67890 \
  -H 'Authorization: Bearer <jwt_token>'
```

## Additional Notes

1. **Database Connections**
   - All databases are MySQL instances
   - Use MySQL Workbench or similar clients for GUI access
   - SSL/TLS is required for production database connections
   - Keep credentials secure and do not share them

2. **Function Testing**
   - All function calls require valid JWT token from login-ms
   - Replace [region] with actual OCI region (e.g., us-sanjose-1)
   - API Gateway endpoints are protected and rate-limited

3. **Monitoring**
   - All services expose a /health endpoint
   - Use OCI monitoring dashboard for metrics and alerts

For detailed information about each microservice, refer to their individual README files in their respective directories.
