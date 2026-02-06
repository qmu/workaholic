# Update standard document architecture of specs 

* when "/scan" command is triggered, I want you to generate or update standard document architecture of specs for the user of this plugin.
* spec = aspect, optics and viewpoint that describes the repository
* 100 specs to see a repository
* each viewpoint should be described by a "architecture-analyst" sub agent concurrently
* each viewpoint should be described in a single markdown file in .workaholic/specs/
* viewpoint needs to be injectable via user-repository's root CLAUDE.md
* when there is nesting spec, create directory and make README.md there
* as standard specs of this plugin, include below if there is not modification in the user's root CLAUDE.md
* each viewpoint is strongly encouraged to visualize idea by mermaid diagram
  * e.g. system architecture diagram, user flow diagram, infrastructure diagram, dependency graph, etc.
* when AI generate something not obvious, be honest and add "assumption" section to explain the reason why AI generate such content
* comprehensiveness and correctness are the priority than brevity
* even if there is no explicit information in the repository, try to infer and propose reasonable baseline by analyzing the repository structure, code, document, commit history, etc.

### 1.Stakeholder
The people and teams involved with the software — their roles, responsibilities, and interests in the project's outcome. The concrete problems they face today and the value they expect the software to deliver.
### 2.Model
The primary real-world concepts, objects, or processes the software models — their attributes, behaviors, and relationships. The domain knowledge and business rules that govern how these entities interact.
### 3.Usecase
The prioritized user scenarios the software supports, selected from the broader space of possible interactions.
### 4.Infrastructure
The deployment targets (cloud, on-prem, edge, etc.), runtime environments, and how infrastructure is provisioned and managed.
### 5.Application
The compilable or publishable units (packages, services, executables) this repository produces, and how they compose into running applications.
### 6.Component
The internal building blocks within each package — modules, classes, layers — and their interaction patterns and dependency graph.
### 7.Data
The data lifecycle: schemas, sources, transformations, storage mechanisms, and output formats the system handles.
### 8.Feature
The user-facing capabilities the system exposes, their boundaries, and how they depend on or interact with each other.

----------------


## 4.Reliability

### 4-1.Assurance
The verification and validation strategy — testing levels, coverage targets, and processes that ensure correctness.
### 4-2.Security
The assets worth protecting, threat model, authentication/authorization boundaries, and safeguards in place.
### 4-3.Quality
Code quality standards, linting rules, review processes, and metrics (e.g., complexity, duplication) used to maintain maintainability.
### 4-4.Accessibility
Compliance targets (WCAG levels, i18n support), assistive technology considerations, and inclusive design practices.
### 4-5.Delivery
The CI/CD pipeline stages, deployment strategies (blue-green, canary, etc.), and artifact promotion flow from source to production.
### 4-6.Backup
Data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets.



### 1-3.Project
The current objectives of this repository, their success criteria, milestones, timelines, and how progress is measured over time. The people, budgets, tools, and external dependencies required, and how they are allocated across the project.

