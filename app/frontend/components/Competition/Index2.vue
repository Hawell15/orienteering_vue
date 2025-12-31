<template>
    <h1 style="text-align:center; color:green">Competiții</h1>
    <input type="text" v-model="filters.search" placeholder="Cautare" class="form-control" />
    <hr>
    <div class="filter-item">
        <label for="country" class="label-filter">Țara</label>
        <select id="country" v-model="filters.country" class="custom-select">
            <option value="all">Toate</option>
            <option value="international">Internaționale</option>
            <option v-for="country in filterData.countries" :key="country" :value="country">
                {{ country }}
            </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="distance_type" class="label-filter">Tipul Distanței</label>
        <select id="distance_type" v-model="filters.distance_type" class="custom-select">
            <option value="all">Toate</option>
            <option v-for="distance_type in filterData.distance_types" :key="distance_type" :value="distance_type">
                {{ distance_type }}
            </option>
        </select>
    </div>
    <div class="filter-item">
        <label for="distance_type" class="label-filter">WRE</label>
        <input type="checkbox" name="wre" id="wre" class="custom-select" v-model="wre">
    </div>
    <div class="filter-item">
        <label class="label-filter">Data</label>
        <div class="range-wrapper">
            <input type="date" v-model="filters['date[from]']" min="0" class="custom-input"/>
            <span class="range-separator">—</span>
            <input type="date" v-model="filters['date[to]']" min="0" class="custom-input" placeholder="Până la" />
        </div>
    </div>

    <button class="btn btn-sm btn-danger" @click="resetFilters">Reseteaza Filtrele</button>
    <hr>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('date')">Data</th>
                <th @click="orderTable('competition_name')">Nume</th>
                <th @click="orderTable('location')">Oraș</th>
                <th @click="orderTable('country')">Țara</th>
                <th @click="orderTable('distance_type')">Tipul Distanței</th>
                <th @click="orderTable('wre_id')">WRE ID</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in data" :key="element.id">
                <td><a :href="`competitions/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`competitions/${element.id}`">{{ element.date }}</a></td>
                <td><a :href="`competitions/${element.id}`">{{ element.competition_name }}</a></td>
                <td>{{ element.location }}</td>
                <td>{{ element.country }}</td>
                <td>{{ element.distance_type }}</td>
                <td>{{ element.wre_id }}</td>
                <td>
                    <a class="btn btn-sm btn-warning" :href="`competitions/${element.id}`">
                        Arată
                    </a>
                </td>
                <td>
                    <button class="btn btn-sm btn-success" @click="editElement(element)">
                        Editează
                    </button>
                </td>
                <td>
                    <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                        Șterge
                    </button>
                </td>
            </tr>
        </tbody>
    </table>
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from 'axios'

const data = ref([])
const distanceTypes = ref([])
const countries = ref([])

const DEFAULT_FILTERS = {
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc",
    "date[from]": "2000-01-01",
    "date[to]": "2100-01-01",
    "search": "",
    "country": "all",
    "distance_type": "all"
}

let debounceTimeout = null;

watch(
    filters,
    (newVal) => {
        clearTimeout(debounceTimeout);

        debounceTimeout = setTimeout(() => {
            getData();
        }, 400);
    }, { deep: true }
);

async function getData() {
    const cleanParams = {};

    const rangePairs = [
        { from: "date[from]", to: "date[to]" },
    ];

    const keysToSkip = new Set();

    if (filters.search === "") {
        keysToSkip.add("search")
    }

    rangePairs.forEach(pair => {
        const currentFrom = filters[pair.from];
        const currentTo = filters[pair.to];
        const defaultFrom = DEFAULT_FILTERS[pair.from];
        const defaultTo = DEFAULT_FILTERS[pair.to];

        if (currentFrom === defaultFrom && currentTo === defaultTo) {
            keysToSkip.add(pair.from);
            keysToSkip.add(pair.to);
        }
    });

    Object.keys(filters).forEach(key => {
        let value = filters[key];

        if (keysToSkip.has(key)) return;

        if (value === "all") return;

        if (key !== 'search' && (value === "" || value === null)) {
            value = DEFAULT_FILTERS[key];
        }

        cleanParams[key] = value;
    });

    try {
        const res = await axios.get('/categories.json', { params: cleanParams });
        data.value = res.data;

        const queryString = new URLSearchParams(cleanParams).toString();
        const urlPrefix = window.location.pathname;
        const newUrl = queryString ? `${urlPrefix}?${queryString}` : urlPrefix;

        window.history.replaceState({}, '', newUrl);
    } catch (error) {
        console.error("API Error:", error);
    }
}

onMounted(() => {
    const urlParams = new URLSearchParams(window.location.search);

    urlParams.forEach((value, key) => {
        if (key in filters) {
            const isNumber = typeof DEFAULT_FILTERS[key] === 'number';
            filters[key] = isNumber ? Number(value) : value;
        }
    });
    getData();
})

function orderTable(sortKey) {
    const isCurrentSort = filters["sorting[sort_by]"] === sortKey;
    const currentDir = filters["sorting[direction]"];

    filters["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters["sorting[sort_by]"] = sortKey;
}

async function getFiltersData() {
    const res = await axios.get('/competitions/filters.json')
    filterData.value = res.data
}


function resetFilters() {
    filters.value = []
    getData();
}
</script>

