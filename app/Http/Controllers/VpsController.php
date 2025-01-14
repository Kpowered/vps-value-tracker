<?php

namespace App\Http\Controllers;

use App\Models\Vps;
use Illuminate\Http\Request;
use Carbon\Carbon;

class VpsController extends Controller
{
    public function index()
    {
        $vpsList = Vps::all();
        return view('vps.index', compact('vpsList'));
    }

    public function create()
    {
        return view('vps.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'vendor_name' => 'required',
            'cpu_model' => 'required',
            'cpu_cores' => 'required|integer',
            'memory_gb' => 'required|integer',
            'storage_gb' => 'required|integer',
            'bandwidth_gb' => 'required|integer',
            'price' => 'required|numeric',
            'currency' => 'required|size:3',
        ]);

        $validated['start_date'] = Carbon::now();
        $validated['end_date'] = Carbon::now()->addYear();

        Vps::create($validated);

        return redirect()->route('vps.index')->with('success', 'VPS added successfully');
    }

    public function destroy(Vps $vps)
    {
        $vps->delete();
        return redirect()->route('vps.index')->with('success', 'VPS deleted successfully');
    }
} 