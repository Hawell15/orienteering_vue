<template>
    <div class="index-page">
        <div class="index-hero">
            <div class="index-hero-inner">
                <div class="index-title-block">
                    <span class="index-eyebrow">🏅 Listă</span>
                    <h1 class="index-title">Rezultate</h1>
                </div>
                <span class="index-count">{{ data.length }}</span>
                <div class="search-box">
                    <input type="text" v-model="filters.search" placeholder="Caută rezultate…" class="search-input" />
                </div>
                <button class="add-btn" @click="createNew">＋ Adaugă rezultat</button>
            </div>
        </div>

        <div class="filter-panel">
            <div class="filter-panel-head">
                <span class="filter-panel-title">⚙ Filtre</span>
                <button class="reset-btn" @click="resetFilters">Resetează</button>
            </div>
            <div class="filter-grid">
                <div class="filter-item">
                    <label for="runner" class="label-filter">Sportiv</label>
                    <select id="runner" v-model="filters.runner" class="custom-select">
                        <option value="all">Toți</option>
                        <option v-for="r in filterData.runners" :key="r.id" :value="r.id">{{ r.full_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="club" class="label-filter">Club</label>
                    <select id="club" v-model="filters.club" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="club in filterData.clubs" :key="club.id" :value="club.id">{{ club.club_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="competition" class="label-filter">Competiția</label>
                    <select id="competition" v-model="filters.competition" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="c in filterData.competitions" :key="c.id" :value="c.id">{{ c.competition_name }}</option>
                    </select>
                </div>
                <div v-if="filterData.groups" class="filter-item">
                    <label for="group" class="label-filter">Grupe</label>
                    <select id="group" v-model="filters.group_data" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="g in filterData.groups" :key="g.id" :value="g.id">{{ g.group_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="category" class="label-filter">Categoria îndeplinită</label>
                    <select id="category" v-model="filters.category" class="custom-select">
                        <option value="all">Toate</option>
                        <option v-for="cat in filterData.categories" :key="cat.id" :value="cat.id">{{ cat.category_name }}</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Data</label>
                    <div class="range-wrapper">
                        <input type="date" v-model="filters['date[from]']" class="custom-input" />
                        <span class="range-separator">—</span>
                        <input type="date" v-model="filters['date[to]']" class="custom-input" />
                    </div>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Indicatori</label>
                    <div class="checkbox-row">
                        <label class="checkbox-pill" :class="{ checked: filters.wre === true || filters.wre === 'true' }">
                            <input type="checkbox" v-model="filters.wre" /> WRE
                        </label>
                        <label class="checkbox-pill" :class="{ checked: filters.ecn === true || filters.ecn === 'true' }">
                            <input type="checkbox" v-model="filters.ecn" /> ECN
                        </label>
                    </div>
                </div>
                <div class="filter-item">
                    <label class="label-filter">Îndeplinire</label>
                    <div class="checkbox-row">
                        <label class="checkbox-pill" :class="{ checked: filters.status.includes('confirmed') }">
                            <input type="checkbox" value="confirmed" v-model="filters.status" /> Îndeplinit
                        </label>
                        <label class="checkbox-pill" :class="{ checked: filters.status.includes('pending') }">
                            <input type="checkbox" value="pending" v-model="filters.status" /> În așteptare
                        </label>
                        <label class="checkbox-pill" :class="{ checked: filters.status.includes('unconfirmed') }">
                            <input type="checkbox" value="unconfirmed" v-model="filters.status" /> Fără îndeplinire
                        </label>
                    </div>
                </div>
            </div>
        </div>

        <div class="table-card">
            <div class="table-scroll">
                <Table :elements="data" @order="orderTable" @refresh="() => window.location.reload()"></Table>
            </div>
            <div v-if="data.length === 0" class="empty-state">
                <div class="empty-state-icon">🔍</div>
                <div>Nu s-au găsit rezultate.</div>
            </div>
        </div>

        <Create ref="modal" @save="saveResult" />
    </div>
</template>
<script setup>
import { reactive, ref, onMounted, watch } from 'vue'
import axios from '@/axios'
import Create from './Create.vue'
import Table from './Table.vue'
const data = ref([])
const filterData = ref({})
const competitionValue = ref("")

const DEFAULT_FILTERS = {
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc",
    "date[from]": "2000-01-01",
    "date[to]": "2100-01-01",
    "search": "",
    "club": "all",
    "runner": "all",
    "competition": "all",
    "category": "all",
    "wre": "false",
    "ecn": "false",
    "group_data": "all",
    "status": []
}

const filters = reactive({ ...DEFAULT_FILTERS });

const modal = ref(null)
let debounceTimeout = null;

watch(
    filters,
    () => {
        clearTimeout(debounceTimeout);
        debounceTimeout = setTimeout(() => {
            getData();
        }, 400);
    }, { deep: true }
);

async function getData() {
    getFiltersGroupData();
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
        if (value === "false" || value === false) return;
        if (key === 'status' && value.length === 0) return;
        if (key !== 'search' && (value === "" || value === null)) {
            value = DEFAULT_FILTERS[key];
        }

        cleanParams[key] = value;
    });

    try {
        const res = await axios.get('/results.json', { params: cleanParams });
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
    getFiltersData()
    const urlParams = new URLSearchParams(window.location.search);
    urlParams.forEach((value, key) => {
        if (key in filters) {
            const isNumber = typeof DEFAULT_FILTERS[key] === 'number';
            filters[key] = isNumber ? Number(value) : value;
        }
    })
    getData();
})

function orderTable(sortKey) {
    const isCurrentSort = filters["sorting[sort_by]"] === sortKey;
    const currentDir = filters["sorting[direction]"];

    filters["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters["sorting[sort_by]"] = sortKey;
}

async function getFiltersData() {
    const cleanParams = {};
    cleanParams["competition"] = filters.competition

    const res = await axios.get('/results/filters.json', { params: cleanParams })

    filterData.value = res.data
}

async function getFiltersGroupData() {
    if (filters.competition === competitionValue.value) return
    competitionValue.value = filters.competition

    delete filters.group_data

    if (filters.competition === "all") {
        delete filterData.value.groups
        return;
    }
    const res = await axios.get(`/competitions/${filters.competition}/group_filters.json`)

    filterData.value.groups = res.data.groups
}

function resetFilters() {
    Object.assign(filters, { ...DEFAULT_FILTERS, status: [] })
    getData();
}

function createNew() {
    modal.value.createNew()
}

function saveResult() {
    filters["sorting[sort_by]"] = "created_at"
    filters["sorting[direction]"] = "desc"
}
</script>

<style scoped src="../shared/index.css"></style>
