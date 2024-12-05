flowchart TB
    %% External Systems
    User([Internet User])
    GitHub[(GitHub Repository)]
    GCS[(GCS Backend Bucket)]
    
    %% GitHub Actions
    subgraph "GitHub Actions Pipeline"
        direction TB
        Actions["GitHub Actions Runner"]
        Init["terraform init"]
        Validate["terraform validate"]
        ApplyGCP["terraform apply\n(GCP Infrastructure)"]
        ApplyAll["terraform apply\n(All Resources)"]
        
        Actions --> Init
        Init --> Validate
        Validate --> ApplyGCP
        ApplyGCP --> ApplyAll
    end
    
    %% Infrastructure
    subgraph "GCP Infrastructure"
        direction TB
        GlobalIP["Global IP"]
        
        subgraph "VPC Network"
            direction TB
            Ingress["GCP Load Balancer/\nIngress Controller"]
            
            subgraph "GKE Cluster"
                direction TB
                Service["WordPress Service\n(NodePort)"]
                Deploy["WordPress Deployment\n(Pods)"]
                NFS["NFS Server"]
                NFSPVC["NFS PVC"]
                
                Service --> Deploy
                NFS --> NFSPVC
                NFSPVC --> Deploy
            end
            
            subgraph "Cloud SQL"
                direction TB
                MySQL["MySQL Instance\n(Private IP)"]
            end
        end
    end
    
    %% Monitoring
    subgraph "Monitoring"
        direction TB
        Alerts["Alert Policy"]
        Email["Email Channel"]
        
        Alerts --> Email
    end
    
    %% Flow Connections
    User --> GlobalIP
    GlobalIP --> Ingress
    Ingress --> Service
    Deploy --> MySQL
    
    %% CI/CD Flow
    GitHub --> Actions
    Init -- "State Management" --> GCS
    
    %% Monitoring Flow
    Deploy -. "Metrics" .-> Alerts
    
    %% Styling
    classDef external fill:#f9f,stroke:#333,stroke-width:2px
    classDef action fill:#bbf,stroke:#333,stroke-width:1px
    classDef infrastructure fill:#bfb,stroke:#333,stroke-width:1px
    classDef monitoring fill:#fbf,stroke:#333,stroke-width:1px
    
    class User,GitHub,GCS external
    class Actions,Init,Validate,ApplyGCP,ApplyAll action
    class GlobalIP,Ingress,Service,Deploy,NFS,NFSPVC,MySQL infrastructure
    class Alerts,Email monitoring