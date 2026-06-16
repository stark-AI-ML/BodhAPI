## Rollback_concept

- BEGIN; (or START TRANSACTION;) → starts a transaction.

        You can then run multiple queries inside that transaction.


- If something goes wrong before you commit, you can issue ROLLBACK.

      - PostgreSQL will undo all changes made in that transaction.


- Once you run COMMIT; 

       Transaction is finalized and written permanently to the database. At that point, you cannot roll back anymore — the changes are durable.


## ROLLBACK is only possible while the transaction is still open. 


### After COMMIT, rollback is no longer possible.
