use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateVpsTable extends Migration
{
    public function up()
    {
        Schema::create('vps', function (Blueprint $table) {
            $table->id();
            $table->string('vendor_name');
            $table->string('cpu_model');
            $table->integer('cpu_cores');
            $table->integer('memory_gb');
            $table->integer('storage_gb');
            $table->integer('bandwidth_gb');
            $table->decimal('price', 10, 2);
            $table->string('currency');
            $table->timestamp('start_date');
            $table->timestamp('end_date');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('vps');
    }
} 